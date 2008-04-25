class Catalog < ActiveRecord::Base
  has_many :images
  
  def self.default
    @default_catalog ||= find(:first)
  end
  
  
end
