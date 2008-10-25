# ActsAsPolymorphTaggable
module Hermes
  module Polymorph
    module Taggable
      # We have a version of find_tagged_with because for polymorphs the tags are actually on the
      # Asset table, so we need to join to that table, then that table to the Tags information
      def self.included(base)
        base.extend(ClassMethods)
      end
    
      module ClassMethods
        def acts_as_polymorph_taggable
          named_scope :tagged_with, lambda {|*tags|
            options = (tags.last && tags.last.is_a?(Hash)) ? tags.pop : {}
            if tags.first
              sql = tagged_with_options(Tag.unsynonym(tags.first), options)
              subquery = "#{polymorph_table_name}.id IN (SELECT #{sql[:select]} FROM #{polymorph_table_name} #{sql[:joins]} WHERE #{sql[:conditions]})"
              { :conditions => subquery, :include => polymorph_name.to_sym }
            else
              { }
            end
          }
        end
        
        def find_tagged_with(*args)
          #args = args.pop if args.size == 1
          options = tagged_with_options(*args)
          options.blank? ? [] : find(:all, options)
        end
    
        def tagged_with_options(tags, options = {})
          tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)
          options = options.dup

          return {} if tags.empty?

          conditions = []
          conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]
          #conditions << sanitize_sql(scope(:find)[:conditions]) if scope(:find)
          conditions.compact!

          taggings_alias, tags_alias = "#{polymorph_name}_taggings", "#{polymorph_name}_tags"

          if options.delete(:exclude)
            conditions << <<-END
              #{polymorph_table_name}.id NOT IN
                (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name}
                  INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                  WHERE #{tags_condition(tags)} AND #{Tagging.table_name}.taggable_type = #{quote_value(polymorph_class_name)})
            END
          else
            if options.delete(:match_all)
              conditions << <<-END
                (SELECT COUNT(*) FROM #{Tagging.table_name}
                  INNER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id
                  WHERE #{Tagging.table_name}.taggable_type = #{quote_value(polymorph_class_name)} AND
                        taggable_id = #{polymorph_table_name}.id AND
                        #{tags_condition(tags)}) = \#{tags.size}
              END
            else
              conditions << tags_condition(tags, tags_alias)
            end
          end

          { :select => "DISTINCT #{polymorph_table_name}.id",
            :joins => "INNER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{polymorph_table_name}.#{primary_key} " +
                      "INNER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id ",
            :conditions => conditions.join(" AND ")
          }.reverse_merge!(options)
        end

        def tags_condition(tags, table_name = Tag.table_name)
          condition = tags.map { |t| sanitize_sql(["#{table_name}.name LIKE ?", t]) }.join(" OR ")
          "(" + condition + ")"
        end
      end
    end
  end
end
