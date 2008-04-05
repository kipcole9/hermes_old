class Catalog < ActiveRecord::Base
  has_many :images
  
  def self.default_catalog
    @default_catalog ||= find(:first)
  end
  
  
end
