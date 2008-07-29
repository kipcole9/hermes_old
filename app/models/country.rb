class Country < ActiveRecord::Base
  has_many :assets
 
  def self.select_array
    find(:all, :select => "name").collect!{|c| c.name}  
  end
  
end
