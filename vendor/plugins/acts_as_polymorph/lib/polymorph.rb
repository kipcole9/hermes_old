module ActiveRecord
  module Acts #:nodoc:
    module Polymorph #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_polymorph(options = {})
          configuration = { :name => :asset, :as => :content }
          configuration.update(options) if options.is_a?(Hash)
          
          polymorph_name = configuration[:name].to_s.downcase
          polymorph_class_name = polymorph_name.capitalize
          polymorph_table_name = Inflector.pluralize(polymorph_name)
          my_table_name = Inflector.pluralize(base_class.name).downcase
          as_name = configuration[:as].to_s.downcase
          
          class_eval <<-END_EVAL
            has_one :#{polymorph_name}, :as => :#{as_name}
            
            def acts_as_polymorph_class
              ::#{self.name}
            end
            
            def self.polymorph_class
              #{polymorph_class_name}
            end
            
            def initialize(attrs = nil)
              super(nil)
              self.#{polymorph_name} = #{polymorph_class_name}.new
              self.attributes = attrs
              self
            end
            
            # We have a version of find_tagged_with because for polymorphs the tags are actually on the
            # Asset table, so we need to join to that table, then that table to the Tags information
            def self.find_tagged_with(*args)
              #args = args.pop if args.size == 1
              options = find_options_for_find_tagged_with(*args)
              options.blank? ? [] : find(:all, options)
            end

            def self.find_options_for_find_tagged_with(tags, options = {})
              tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
              options = options.dup

              return {} if tags.empty?

              conditions = []
              conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]
              conditions << sanitize_sql(scope(:find)[:conditions]) if scope(:find)
              conditions.compact!

              taggings_alias, tags_alias = "#{polymorph_name}_taggings", "#{polymorph_name}_tags"

              if options.delete(:exclude)
                conditions << <<-END
                  #{polymorph_table_name}.id NOT IN
                    (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name}
                      INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                      WHERE \#{tags_condition(tags)} AND #{Tagging.table_name}.taggable_type = #{quote_value(polymorph_class_name)})
                END
              else
                if options.delete(:match_all)
                  conditions << <<-END
                    (SELECT COUNT(*) FROM #{Tagging.table_name}
                      INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                      WHERE #{Tagging.table_name}.taggable_type = #{quote_value(polymorph_class_name)} AND
                            taggable_id = #{polymorph_table_name}.id AND
                            \#{tags_condition(tags)}) = \#{tags.size}
                  END
                else
                  conditions << tags_condition(tags, tags_alias)
                end
              end

              { :select => "DISTINCT #{my_table_name}.*", 
                :joins => "INNER JOIN #{polymorph_table_name} ON #{my_table_name}.id = #{polymorph_table_name}.content_id AND #{polymorph_table_name}.content_type = '#{self.name}' " +
                          "INNER JOIN #{Tagging.table_name} \#{taggings_alias} ON \#{taggings_alias}.taggable_id = #{polymorph_table_name}.#{primary_key} " +
                          "INNER JOIN #{Tag.table_name} \#{tags_alias} ON \#{tags_alias}.id = \#{taggings_alias}.tag_id ",
                :conditions => conditions.join(" AND ")
              }.reverse_merge!(options)
            end

            def self.tags_condition(tags, table_name = Tag.table_name)
              condition = tags.map { |t| sanitize_sql(["\#{table_name}.name LIKE ?", t]) }.join(" OR ")
              "(" + condition + ")"
            end

            def self.method_missing(name, *args)
              if name.to_s.match(/^find_poly/)
                new_name = name.to_s.gsub(/^find_poly/,"find")
                with_scope(:find => {:include => :#{polymorph_name}}) do
                  send(new_name, args)
                end
              else
                super
              end
            end

            define_delegate_methods(#{polymorph_class_name})
            define_instance_methods(#{polymorph_class_name})
          END_EVAL
        end
        
        # Attribute methods that proxy the Asset class attributes so we can mass assign
        # and otherwise update as if they were in this class
        def define_delegate_methods(polymorph_class_name)
          polymorph_name = polymorph_class_name.to_s.downcase
          polymorph_class_name.content_columns.each do |attr|
            class_eval <<-END_EVAL
              def #{attr.name}
                return self.#{polymorph_name}.#{attr.name}
              end
              def #{attr.name}= (val)
                self.#{polymorph_name}.#{attr.name} = val
              end
            END_EVAL
          end
        end
        
        # Instance methods to synchronise saving between the two classes
        def define_instance_methods(polymorph_class_name)
          polymorph_name = polymorph_class_name.to_s.downcase
          class_eval <<-END_EVAL          
            def save(f = true)
              # Save on a new record will also automatically save the Asset record
              acts_as_polymorph_class.transaction do
                is_new = self.new_record?
                if result = super
                  result = self.#{polymorph_name}.save(f) unless is_new
                  self.#{polymorph_name}.errors.each {|e, m| self.errors.add(e, m)} if !result
                else
                  # for cases where the polymorph save is automatic
                  self.#{polymorph_name}.errors.each {|e, m| self.errors.add(e, m)}
                end
                raise "Bad polymorphic save" if !result # Raise forces rollback
                true
              end
            rescue
              false
            end
            
            def destroy
              acts_as_polymorph_class.transaction do
                if result = super
                  result = self.#{polymorph_name}.destroy if result
                  self.#{polymorph_name}.errors.each {|e, m| self.errors.add(e, m)} if !result
                end
              end
            end                     

            def save!
              is_new = self.new_record?
              puts "New record" if is_new
              acts_as_polymorph_class.transaction do
                puts "About to save! on main record"
                if result = super
                  puts "About to save! on polymorph record" unless is_new
                  result = self.#{polymorph_name}.save! unless is_new
                  self.#{polymorph_name}.errors.each {|e, m| self.errors.add(e, m)} if !result
                end
              end
            end 
            
            def to_param
              self.name
            end
            
            def tag_list
              self.#{polymorph_name}.tag_list
            end
            
            def tag_list=(t)
              self.#{polymorph_name}.tag_list=(t)
            end
            
            def comments
              self.#{polymorph_name}.comments
            end
            
            def asset_id
              self.#{polymorph_name}.id
            end
            
            def geocode
              self.#{polymorph_name}.geocode
            end
            
            def mappable?
              self.#{polymorph_name}.mappable?
            end
            
            def category_ids
              self.#{polymorph_name}.category_ids
            end
            
            def category_ids=(ids)
              self.#{polymorph_name}.category_ids = ids
            end
            
            def categories
              self.#{polymorph_name}.categories
            end
            
            def comments_open?
              Publication.default.allow_comments == Asset::ALLOW_COMMENTS[:open] && 
                self.#{polymorph_name}.allow_comments == Asset::ALLOW_COMMENTS[:open]
            end
            
            def comments_closed?
              Publication.default.allow_comments == Asset::ALLOW_COMMENTS[:closed] || 
                self.#{polymorph_name}.allow_comments == Asset::ALLOW_COMMENTS[:closed]
            end            
            
            def comments_none?              
              Publication.default.allow_comments == Asset::ALLOW_COMMENTS[:none] || 
                self.#{polymorph_name}.allow_comments == Asset::ALLOW_COMMENTS[:none]
            end
            
            def content_rating_description
              self.#{polymorph_name}.content_rating_description
            end
            
            def status_description
              self.#{polymorph_name}.status_description
            end
            
          END_EVAL
        end
      end

      module InstanceMethods

      end
    end
  end
end
