class Gallery < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  acts_as_mappable            :default_units => :kms, :lat_column_name => 'latitude', :lng_column_name => 'longitude', :delegate => :asset
    
  has_many      :slides, :order => "position", :dependent => :destroy
  has_many      :images, :through => :slides
  after_save    :refresh
  
  DEFAULT_ITEM_LIMIT        = 12
  DEFAULT_PAGE_SIZE         = 6
  
  def gallery_of=(folder)
    super(folder.with_slash) if folder && folder.is_a?(String)
  end
  
  def popular_image(current_user)
    Image.viewable_by(current_user).find(:first, :include => [:galleries, :slides], 
        :conditions => ["galleries.id = ?", attributes['id']],
        :order => "view_count DESC")
  end

  # Announce articles to Defensio spam analyser?
  def self.defensio?
    true
  end

private
  def refresh
    images = Image.find_all_by_folder(self.gallery_of) if self.gallery_of
    images.each do |i|
      add_to_collection(i)
    end
  end
  
  def add_to_collection(image)
    # Ignore duplicates
    self.images << image rescue nil
  end
end