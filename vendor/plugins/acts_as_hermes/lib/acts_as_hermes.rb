module Hermes
  module ModelExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    include ActionController::UrlWriter   

    # For pingbacks
    def add_pingback(sourceURI, body)
      Comment.add_pingback(self, sourceURI, body)
    end

    # Announce articles to Defensio spam analyser?
    def self.defensio?
      true
    end
      
    def author_name
      self.created_by.full_name
    end

    def author_email
      self.asset.created_by_email
    end

    def create_date
      self.asset.created_at.strftime("%Y/%m/%d")
    end
  
    def to_param
      self.name
    end
      
    def permalink
      send("#{self.class.name.downcase}_url", self, :host => Publication.current.domain)
    end

    module ClassMethods 
      def acts_as_hermes
        # Control finders that can be chained (they are really scope methods)
        named_scope :published,  {:conditions => Asset.published_policy}
        named_scope :mappable,   { :conditions => '(assets.latitude IS NOT NULL AND assets.latitude <> 0) AND (assets.longitude IS NOT NULL AND assets.longitude <> 0)',
                                   :include => polymorph_name.to_sym }        
        named_scope :popular,    lambda {|num| {:order => "view_count DESC", :limit => num, :include => polymorph_name.to_sym } }
        named_scope :unpopular,  lambda {|num| {:order => "created_at ASC", :limit => num, :include => polymorph_name.to_sym } }
        named_scope :recent,     lambda {|num| {:order => "created_at DESC", :limit => num, :include => polymorph_name.to_sym } }        
        named_scope :conditions, lambda {|where| { :conditions => where } }
        named_scope :order,      lambda {|order| { :order => order } }
        named_scope :limit,      lambda {|limit| { :limit => limit } }
        
        named_scope :included_in_index, lambda { |*user|
          (user.first && user.first.is_admin?) ? {:conditions => "#{polymorph_table_name}.include_in_index = 1", :include => polymorph_name.to_sym} : { }
        }

        named_scope :published_in, lambda {|publication| 
          { :conditions => ["assets.publications & ?", publication.bit_id], :include => polymorph_name.to_sym }
        }
        
        named_scope :category_of, lambda {|*cat| 
          if cat.first
            {:conditions => "#{table_name}.id in (select #{table_name}.id \
                from #{table_name} join assets on #{table_name}.id = #{polymorph_table_name}.content_id and #{polymorph_table_name}.content_type = '#{self.name}' \
                    join assets_categories on #{polymorph_table_name}.id = assets_categories.asset_id \
                    join categories on categories.id = assets_categories.category_id \
                    where categories.name = '#{cat.first}')" }
          else
            { }
          end
        }
      end
           
      def default_url_options
        { :host => Publication.current.domain }
      end
      
      # Standard access method
      def viewable(user, publication)
        published_in(publication).published.viewable_by(user).included_in_index(user)
      end
      
    end
  end
end
