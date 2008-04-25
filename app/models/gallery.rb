class Gallery < ActiveRecord::Base
  include HermesModelExtensions
  acts_as_polymorph
  acts_as_secure
  has_many      :slides, :order => "position"
  has_many      :images, :through => :slides
  before_save   :try_geocode 
  
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
    
  def to_xml(options = {})
    gallery_xml = Builder::XmlMarkup.new(:indent => 2)
    gallery_xml.gallery(:name => self.name, :created_by => self.created_by.email) do |xml|
      xml.gallery_of(self.gallery_of)
      asset_xml(self, xml)
    end
  end
  
  def create_metadata_template(catalog_directory)
    filename = self.gallery_of ? catalog_directory + self.gallery_of + METADATA_FILENAME : catalog_directory + METADATA_FILENAME
    if !File.exist?(filename) || File.mtime(filename) < self.updated_at
      metafile = File.open(filename, File::WRONLY|File::TRUNC|File::CREAT)
      metafile.puts self.to_xml
      metafile.close
    end
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
    creator_email = xml.root.attributes["email"]
    gallery.created_by = User.find_by_email(creator_email) unless creator_email.blank?
    xml.root.elements.each do |e|
      data[e.name.to_sym] = e.text
    end  
    retcode = gallery.new_record? ? :inserted_metatdata : :updated_metadata
    if !gallery.update_attributes(data)
      puts gallery.errors.inspect 
      return :bad_update
    end
    
    # Add images to the gallery and geocode its location
    if gallery.gallery_of
      # Slide.delete_all(["gallery_id = ?", gallery.id])
      gallery.images = Image.find_all_by_folder(gallery.gallery_of)
    end
    gallery.geocode
    gallery.save!
    retcode
  end
  
  def self.clear_galleries
    find(:all).each do |g|
      g.destroy
      g.slides.each {|s| s.destroy}
    end
    true
  end
  
  def self.create_default_galleries
    galleries = Image.find(:all, :select => "DISTINCT folder")
    galleries.each do |g|
      name = gallery_name_from_folder(g.folder)
      gallery = Gallery.new(:name => name, :title => name.gsub(/-/,' '), :gallery_of => g.folder)
      images = Image.find(:all, :conditions => ["folder = ?", g.folder])
      puts "Found #{images.size} images for gallery #{name}."
      gallery.images << images
      gallery.save!
    end
  end
  
  def self.gallery_name_from_folder(folder)
    parts = folder.sub(/\/$/,'')
  end
  
  def try_geocode
    self.geocode
  end

end