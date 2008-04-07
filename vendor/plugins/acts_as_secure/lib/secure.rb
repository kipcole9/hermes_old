module ActiveRecord
  module Acts #:nodoc:
    module Secure #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_secure(options = {})
          configuration = { :name => :asset }
          configuration.update(options) if options.is_a?(Hash)
          
          polymorph_name = configuration[:name].to_s.downcase
          polymorph_table_name = polymorph_name.pluralize
          
          before_save     :check_update_create_access
          before_destroy  :check_destroy_access
          
          # Control finders that can be chained (they are really scope methods)
          has_finder :published_in, lambda {|publication| { :conditions => ["assets.publications & ?", publication.bit_id], :include => :asset } }
          has_finder :viewable_by, lambda { |user| 
            if user
              { :conditions => Asset.access_policy(user), :include => :asset }
            else
              nil
            end
          }   

          has_finder :published,  lambda { {:conditions => Asset.published_policy} }
          has_finder :popular,    lambda {|num| {:order => "view_count DESC", :limit => num, :include => :asset } }
          has_finder :unpopular,  lambda {|num| {:order => "created_at ASC", :limit => num, :include => :asset } }
          has_finder :recent,     lambda {|num| {:order => "created_at DESC", :limit => num, :include => :asset } }
          has_finder :conditions, lambda {|where| { :conditions => where } }
          has_finder :order,      lambda {|order| { :order => order } }
          has_finder :limit,      lambda {|limit| { :limit => limit } }
          has_finder :with_category, lambda {|cat| 
              unless cat.blank?
                {:conditions => "#{table_name}.id in (select #{table_name}.id \
                    from articles join assets on articles.id = assets.content_id and assets.content_type = '#{self.name}' \
                        join assets_categories on assets.id = assets_categories.asset_id \
                        join categories on categories.id = assets_categories.category_id \
                        where categories.name = '#{cat}')" }
              else
                {:conditions => "1 = 1" }
              end
            }
                
                              
          def find_by_name_or_id(param)
             find_by_name(param) || find_by_id(param)
          end
          
          def find_by_name(param)
            find(:first, :conditions => ["name = ?",param])
          end
          
          def pager(tags, num, per_page = 10)
            tags ? page_tagged_with(tags, num, per_page) : page(num, per_page)
          end
          
          def page(num, per_page =  10)
            find(:all, :page => {:size => per_page, :current => num})
          end
          
          def page_tagged_with(tags, num, per_page = 10)
            find_tagged_with(tags, :page => {:size => per_page, :current => num})
          end
          
          def can_create?(user)
            AssetPermission.can_create?(self.class, user)
          end

          # Calculate the tag counts for all tags.
          # 
          # Options:
          #  :start_at - Restrict the tags to those created after a certain time
          #  :end_at - Restrict the tags to those created before a certain time
          #  :conditions - A piece of SQL conditions to add to the query
          #  :limit - The maximum number of tags to return
          #  :order - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
          #  :at_least - Exclude tags with a frequency less than the given value
          #  :at_most - Exclude tags with a frequency greater than the given value
          
          def self.tag_counts(tags = :all, options = {})
            unless tags.is_a?(Symbol) && tags == :all
              tags_array = tags.split(',') if tags.is_a?(String)
              tags_array = tags if tags.is_a?(Array)
              tags_array = tags.map(&:name) if tags.is_a?(Array) && tags[0] && tags[0].is_a?(Tag)
              conditions = sanitize_sql(["tags.name in (?)", tags_array])              
            else
              conditions = "1 = 1"
            end
            with_scope(:find => {:conditions => conditions}) do
              Tag.find(:all, find_options_for_tag_counts(options))
            end
          end
          
          class_eval <<-END_EVAL
            def self.find_options_for_tag_counts(options = {})
              options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit
              options = options.dup

              scope = scope(:find)
              start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
              end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]
              this_type_only = sanitize_sql(["#{polymorph_table_name}.content_type = ?", "#{table_name.singularize.capitalize}"])

              conditions = [
                "#{Tagging.table_name}.taggable_type = #{quote_value(polymorph_name.capitalize)}",
                options.delete(:conditions),
                start_at,
                end_at,
                scope && sanitize_sql(scope[:conditions]),
                this_type_only
              ]

              conditions << type_condition unless descends_from_active_record? 
              conditions.compact!
              conditions = conditions.join(' AND ')

              joins = ["INNER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
              joins << "INNER JOIN #{polymorph_table_name} ON #{polymorph_table_name}.#{primary_key} = #{Tagging.table_name}.taggable_id"
              joins << "INNER JOIN #{table_name} ON #{polymorph_table_name}.content_id = #{table_name}.#{primary_key}"

              at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
              at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
              having    = [at_least, at_most].compact.join(' AND ')
              # group_by  = "#{Tag.table_name}.id, #{Tag.table_name}.name HAVING COUNT(*) > 0"
              group_by  = "#{Tag.table_name}.name HAVING COUNT(*) > 0"
              group_by << " AND \#{having}" unless having.blank?

              \# { :select     => "#{Tag.table_name}.id, #{Tag.table_name}.name, COUNT(*) AS count", 
              { :select     => "#{Tag.table_name}.name, COUNT(*) AS count", 
                :joins      => joins.join(" "),
                :conditions => conditions,
                :group      => group_by
              }.reverse_merge!(options)
            end
          END_EVAL
          
          include ActiveRecord::Acts::Secure::InstanceMethods
        end
      end

      module InstanceMethods
        def can_update?(user)
          self.asset.can_update?(user)
        end
        
        def can_delete?(user)
          self.asset.can_delete?(user)
        end
        
        def check_update_create_access
          return false if !user = User.current_user
          return self.class.can_create?(user) if self.new_record?
          return self.can_edit?(user)
        end
            
        def check_destroy_access
          return false if !user = User.current_user
          return self.can_delete?(user)
        end
      end
    end
  end
end
