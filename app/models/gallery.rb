class Gallery < ActiveRecord::Base
  include HermesModelExtensions
  acts_as_polymorph
  acts_as_secure
  has_many :slides, :order => "position"
  has_many :images, :through => :slides
  
  METADATA_FILENAME         = "gallery_metadata.xml"
  DEFAULT_ITEM_LIMIT        = 12
  DEFAULT_PAGE_SIZE         = 6
  
  def popular_image(current_user)
    Image.viewable_by(current_user).find(:first, :include => [:galleries, :slides], :conditions => ["galleries.id = ?", attributes['id']],
                      :order => "view_count DESC")
  end
    
  def to_xml(options = {})
    gallery_xml = Builder::XmlMarkup.new(:indent => 2)
    gallery_xml.gallery(:name => self.name, :created_by => self.created_by.email) do |xml|
      xml.title(self.title)
      xml.description(self.description)
      xml.tag_list(self.tag_list)
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
    if File.exist?(file_xml) then
      xml = REXML::Document.new(File.open(file_xml))
    else
      return :no_metadata # No XML data found
    end
  
    # Now we have the xml of the file metadata,
    # check that it's probably our format
    gallery_file = xml.root.name
    return :bad_metadata if gallery_file != "gallery"  # XML found, but not our document
  
    # Parse the file to get the attributes, update and save
    gallery_name = xml.root.attributes["name"]
    creator_email = xml.root.attributes["email"]
    gallery = find(:first, :conditions => ['name = ?', gallery_name], :include => :asset) || Gallery.new
    gallery.name = gallery_name
    gallery.created_by = User.find_by_email(creator_email) unless creator_email.blank?
    xml.root.elements.each do |e|
      data[e.name.to_sym] = e.text
    end  
    retcode = gallery.new_record? ? :inserted_metatdata : :updated_metadata
    if !gallery.update_attributes(data)
      return :bad_update
    end
    
    if gallery.gallery_of
      Slide.delete_all(["gallery_id = ?", gallery.id])
      gallery.images << Image.find_all_by_folder(gallery.gallery_of)
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

end