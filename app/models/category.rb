class Category < ActiveRecord::Base
  has_and_belongs_to_many   :assets
  
  COUNTS = "categories.name, count(categories.name) AS counts"
  
  JOINS = "JOIN assets_categories ON categories.id = assets_categories.category_id " +
          "JOIN assets ON assets.id = assets_categories.asset_id " +
          "JOIN articles ON articles.id = assets.content_id"

  GROUP = "categories.name HAVING count(*) > 0"
  
  ORDER = "name ASC"

  named_scope :counts, lambda { { :select => COUNTS, :joins => JOINS, :group => GROUP, :order => ORDER } }
  named_scope :published_in, lambda {|publication| { :conditions => ["publications & ? > 0", publication.bit_id] } }
  named_scope :order, lambda {|order| {:order => order} }
  named_scope :viewable_by, lambda { |user| 
    if user
      { :conditions => Asset.access_policy(user) }
    else
      nil
    end
  }   
  named_scope :published, lambda { {:conditions => Asset.published_policy} }
  named_scope :group_by, lambda {|group| {:group => group} }

end