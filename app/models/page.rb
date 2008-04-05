class Page < ActiveRecord::Base
  acts_as_list :scope => :article_id
  
  before_validation_on_create   :set_name
  belongs_to :article
  
  # Allows auto page titling in the browser
  def title
    heading
  end
  
private
  def set_name
    self.name = self.name.blank? ? self.title.remove_file_suffix.permalink : self.name 
  end
end