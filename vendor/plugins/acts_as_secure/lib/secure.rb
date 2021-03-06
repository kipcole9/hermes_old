module ActiveRecord
  module Acts #:nodoc:
    module Secure #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_secure(options = {})
          
          before_save     :check_update_create_access
          before_destroy  :check_destroy_access
          
          named_scope :viewable_by, lambda { |*user| 
            u = user.first || User.anonymous
            { :conditions => Asset.access_policy(u), :include => polymorph_name.to_sym }
          }   
                       
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
            
            def self.can_create?(user)
              AssetPermission.can_create?(self.name, user)
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
          self.new_record? ? check_create_access : check_update_access
        end
        
        def check_create_access
          raise Hermes::NoCurrentUser unless User.current_user
          return true if self.class.can_create?(User.current_user)
          self.errors.add("Create", "is not authorised")
          false
        end
        
        def check_update_access
          raise Hermes::NoCurrentUser unless User.current_user
          return true if self.can_update?(User.current_user)
          self.errors.add("Update", "is not authorised for user #{User.current_user.login}")
          false        
        end
        
        def check_destroy_access
          raise Hermes::NoCurrentUser unless User.current_user
          return true if self.can_delete?(User.current_user)
          self.errors.add("Delete", "is not authorised")
          false
        end
      end
    end
  end
end
