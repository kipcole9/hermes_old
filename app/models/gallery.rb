class Gallery < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  has_many      :slides, :order => "position"
  has_many      :images, :through => :slides
  before_save   :set_geocode 
  
  METADATA_FILENAME         = "gallery_metadata.xml"
  GALLERY_SIGNATURE         = "gallery"
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
    
  def self.create_or_update_from_xml(file_xml)
    data = {}
    return(:no_metadata) unless File.exist?(file_xml)
    xml = REXML::Document.new(File.open(file_xml))
  
    # Now we have the xml of the file metadata,
    # check that it's probably our format
    gallery_file = xml.root.name
    return :bad_metadata if gallery_file != GALLERY_SIGNATURE  # XML found, but not our document
  
    # Extract enough from the XML file to see if the Gallery already exists
    gallery_name = xml.root.attributes["name"]
    gallery = find(:first, :conditions => ['assets.name = ?', gallery_name], :include => :asset) || Gallery.new
    
    # Only update if the XML file has been updated more recently than the database
    return :database_more_recent_than_metadata if !gallery.new_record? && gallery.updated_at > File.mtime(file_xml)
    
    # Extract attributes from the XML file and update the Gallery record
    gallery.name = gallery_name
    creator = xml.root.attributes["author"]
    gallery.created_by = User.find_by_email(creator) || User.find_by_login(creator) unless creator.blank?
    xml.root.elements.each do |e|
      data[e.name.to_sym] = e.text
    end  
    retcode = gallery.new_record? ? :inserted_metatdata : :updated_metadata
    if !gallery.update_attributes(data)
      puts gallery.errors.inspect 
      puts gallery.asset.errors.inspect
      return :bad_update
    else
      gallery.images = Image.find_all_by_folder(gallery.gallery_of) if gallery.gallery_of
    end
    retcode
  end
  
  def self.clear_galleries
    find(:all).each do |g|
      g.destroy
      g.slides.each {|s| s.destroy}
    end
    true
  end

private  
  def self.gallery_name_from_folder(folder)
    folder.without_slash
  end
  
  def set_geocode
    self.geocode
    true
  end

end