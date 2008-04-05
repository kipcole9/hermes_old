class Slide < ActiveRecord::Base
  acts_as_list :scope => :gallery_id
  
  belongs_to  :gallery
  belongs_to  :image
end
