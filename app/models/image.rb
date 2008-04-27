class Image < ActiveRecord::Base
  require 'RMagick'
  require 'rexml/document'
  require 'mini_exiftool'
  include HermesImageMetadataImport
  include HermesPrintOrder
  acts_as_polymorph  
  acts_as_secure
                                        
  named_scope :portrait,   :conditions => "orientation = 'p'"
  named_scope :landscape,  :conditions => "orientation = 'l'"
  named_scope :square,     :conditions => "orientation = 's'"
  named_scope :any
                                        
  has_many :slides, :order => "position"
  has_many :galleries, :through => :slides
  
  self.skip_time_zone_conversion_for_attributes = [:taken_at]

  Location_pattern  = /(\d{1,3}) deg (\d{1,2})\' (\d{1,2}\.\d{1,2})\"/
  THUMBNAIL_SUFFIX  = "-thumb"
  SLIDE_SUFFIX      = "-slide"
  DISPLAY_SUFFIX    = "-display"
  TAG_CLOUD_LIMIT   = 30
  ITEM_LIMIT        = 100
  
  belongs_to :catalog
  
  before_save :check_attributes
  
  def self.random(current_user, orient = :any, num = 1)
    case orient
    when :portrait
      results = viewable_by(current_user).portrait.find(:all, :limit => num, :order => "rand()")
    when :landscape
      results = viewable_by(current_user).landscape.find(:all, :limit => num, :order => "rand()")
    when :square
      results = viewable_by(current_user).square.find(:all, :limit => num, :order => "rand()")
    else
      results = viewable_by(current_user).find(:all, :limit => num, :order => "rand()")
    end
    num == 1 ? results.first : results
  end
  
  def display_caption(len = 99999)
    (self.title || self.filename.remove_file_suffix.gsub(/-/," ")).truncate(len)
  end
  
  def caption
    asset.description
  end
  
  def caption=(c)
    asset.description = c
  end
  
  def aperture=(v)
    if v
      a = v.is_a?(Float) ? v.to_s.sub("\.0",'') : v
      a = 'f/' + a if !a.match(/^f\//)
      write_attribute(:aperture, a.gsub(/ +/,''))
    end
  end
  
  def shutter=(v)
    if v
      a = v.to_s.match(/s$/) ? v.to_s : v.to_s + "s"
      write_attribute(:shutter, a)
    end
  end
  
  def lens=(v)
    if v
      l = v.gsub(/\.0/,'').gsub(/ +/,'')
      l = l + "mm" if !l.match(/mm$/)
      write_attribute(:lens, l)
    end
  end
      
  def focal_length=(v)
    if v.is_a?(String)
      l = v.gsub(/\.0/,'').gsub(/ +/,'')
      l = l + "mm" if !l.match(/mm$/)
      write_attribute(:focal_length, l)
    end
  end
  
  def taken_at=(v)
    ta = DateTime.strptime(v,'%Y:%m:%d %H:%M:%S%Z') if v.is_a?(String)
    ta = v if v.is_a?(DateTime)
    write_attribute(:taken_at, ta) if ta
  end
  
  def drive_mode=(v)
    dm = DRIVE_MODE[v] if v.is_a?(Fixnum)
    dm = v if v.is_a?(String)
    write_attribute(:drive_mode, dm) if dm
  end
  
  def focus_mode=(v)
    fm = FOCUS_MODE[v] if v.is_a?(Fixnum)
    fm = v if v.is_a?(String)
    write_attribute(:drive_mode, fm) if fm
  end
  
  # Derive thumbnail file name from the image.
  def thumbnail_filename
    return File.basename(self.filename, ".*") + THUMBNAIL_SUFFIX + File.extname(self.filename)
  end

   # Derive slide file name from the image.
  def slide_filename
    return File.basename(self.filename, ".*") + SLIDE_SUFFIX + File.extname(self.filename)
  end
  
   # Derive thumbnail file name from the image.
  def display_filename
    return File.basename(self.filename, ".*") + DISPLAY_SUFFIX + File.extname(self.filename)
  end
  
  def full_path_name
    return self.catalog.directory + self.folder + self.filename
  end
  
  def thumbnail_path_name
    return self.catalog.directory + self.folder + self.thumbnail_filename
  end
  
  def slide_path_name
    return self.catalog.directory + self.folder + self.slide_filename
  end
  
  def display_path_name
    return self.catalog.directory + self.folder + self.display_filename
  end
  
  def self.thumbnail_suffix
    THUMBNAIL_SUFFIX
  end
  
  def self.slide_suffix
    SLIDE_SUFFIX
  end
  
  def self.display_suffix
    DISPLAY_SUFFIX
  end
  
  def get_shot_data
    @exif = []
    @exif << {:heading => "Location", :item => location, :param => :location}  unless location.blank?
    @exif << {:heading => "City", :item => city, :param => :city}  unless city.blank?
    @exif << {:heading => "State/Prov.", :item => state, :param => :state}  unless state.blank?
    @exif << {:heading => "Country", :item => country, :param => :country}  unless country.blank?
    @exif << {:heading => "Photographer", :item => photographer, :param => :photographer}  unless photographer.blank?
    @exif << {:heading => "Copyright", :item => copyright_notice, :param => false}  unless copyright_notice.blank?
    @exif << {:heading => "Taken at", :item => taken_at.strftime('%a, %b %d %Y at %H:%M'), :param => false}  unless taken_at.blank?
    @exif << {:heading => "Tag List", :item => tag_list.collect!{|t| ["tags", t]}}  unless tag_list.blank?
    @exif << {:heading => "ISO", :item => iso, :param => :iso} unless iso.blank?
    @exif << {:heading => "Aperture", :item => aperture, :param => :aperture} unless aperture.blank?
    @exif << {:heading => "Shutter", :item => shutter, :param => :shutter} unless shutter.blank?
    @exif << {:heading => "Camera", :item => camera_model, :param => "camera_model"}   unless camera_model.blank?
    @exif << {:heading => "Lens", :item => lens, :param => :lens} unless lens.blank?
    @exif << {:heading => "Focal Length", :item => focal_length, :param => :focal_length}  unless focal_length.blank?
    @exif << {:heading => "Flash", :item => flash, :param => :flash}  unless flash.blank?
    return @exif
  end
  
  # Import an image into the Image catalog if the image has not been imported, or if has
  # been updated/edited since last import
  def self.import(file, destination_folder)
    if File.exist?(file) then
      image_filename = File.basename(file)
      if !image = find_by_filename(image_filename)
        image = Image.new
        image.filename = image_filename
        image.catalog = Catalog.default
        image.folder = destination_folder.with_slash
      end
      if image.updated_at.nil? || image.updated_at < File.mtime(file)
        make_image_files(file, destination_folder) 
        image.import_metadata
        image.geocode
        image.save!
      else
        # puts "Image '#{file}' already imported (and up-to-date)"
      end
      image
    else
      puts "Requested file #{file} does not exist - not imported."
      return nil
    end
  end
  
  def import_metadata
    # puts "Import metadata for '#{self.full_path_name}'"
    image_exif = MiniExiftool.new(self.full_path_name)
    MAP.each do |k, v|
      if k == :GPSLatitude
        set_latitude(image_exif)
      elsif k == :GPSLongitude
        set_longitude(image_exif)
      else
        send("#{v.to_s}=", image_exif[k.to_s])
      end
    end
    self.created_by = User.find_by_email(image_exif["CreatorContactInfoCiEmailWork"]) || User.current_user
    check_attributes
    true
  end
  
  def self.import_metadata
    puts "Importing metadata with current user #{User.current_user.full_name}"
    find(:all).each do |i|
       puts "Importing metadata for #{i.filename}"
       i.import_metadata
       i.save!
    end
    true
  end
  
  def self.tag_cloud(current_user)
    # Top tags sorted alphabetically by name
    return viewable_by(current_user).tag_counts(:all, :order => "count desc", :limit => TAG_CLOUD_LIMIT) \
      .sort{|a, b| a.name <=> b.name}
  end
  
  def url
    "image_url_constructor"
  end
  
  def portrait?
    self.orientation == "p"
  end
  
  def landscape?
    self.orientation == "l"
  end
  
  def square?
    self.orientation == "s"
  end

private  
  def check_attributes
    make_title
    make_name
    calculate_orientation
    set_catalog
    set_publication_and_status
  end

  def make_name
    # 'name' is derived from the xmp item 'title'
     self.name ||= self.title.remove_file_suffix.permalink
     if new_record? && Asset.find(:first, :conditions => ["name = ? and content_type = ?", self.name, "Image"])
       self.name = self.name + "-" + self.filename.remove_file_suffix.last(5)
     end
  end
  
  def calculate_orientation
    if self.width && self.height
      self.orientation = self.width > self.height ? "l" : (self.height > self.width ? "p" : "s")
    end
  end
  
  def make_title
    self.title = self.title.blank? ? self.filename.remove_file_suffix.gsub(/-/," ") : self.title
  end
  
  def set_catalog
    self.catalog ||= Catalog.default_catalog
  end
  
  def set_latitude(image_exif)
    if image_exif["GPSLatitude"] && (lat = image_exif["GPSLatitude"].match(Location_pattern))
      #puts "Degrees: '#{$1}', Minutes: '#{$2}', Seconds: '#{$3}'"
      lat_decimal = $1.to_f + ($2.to_f / 60.0) + ($3.to_f / 3600.0)
      lat_decimal = lat_decimal * -1 if image_exif["GPSLatitudeRef"] == "South"
      #puts "Latitude decimal: '#{lat_decimal}'"
      send("latitude=", lat_decimal)
    end
  end

  def set_longitude(image_exif)
    if image_exif["GPSLongitude"] && (lon = image_exif["GPSLongitude"].match(Location_pattern))
      #puts "Degrees: '#{$1}', Minutes: '#{$2}', Seconds: '#{$3}'"
      lon_decimal = $1.to_f + ($2.to_f/60) + ($3.to_f/3600)
      lon_decimal = lon_decimal * -1 if image_exif["GPSLongitudeRef"] == "West"
      #puts "Longitude decimal: '#{lon_decimal}'"
      send("longitude=", lon_decimal)
    end
  end
  
  def set_publication_and_status
    self.publications ||= Publication.default
    self.status ||= Asset::STATUS["published"]
  end
 
  def self.make_image_files(filename, destination_folder)
    puts "Making catalog image files from #{filename}"
    destination = Catalog.default.directory + destination_folder.with_slash
    file_root = File.basename(filename, '.*')
    thumbnail_file = destination + file_root + THUMBNAIL_SUFFIX + ".jpg"
    slide_file = destination + file_root + SLIDE_SUFFIX + ".jpg"
    display_file = destination + file_root + DISPLAY_SUFFIX + ".jpg"
    full_file = destination + file_root + ".jpg"

    image = Magick::ImageList.new(filename)
    
    # Thumbnail
    new_image = image.resize_to_fit(Catalog.default.max_thumbnail_dimension, Catalog.default.max_thumbnail_dimension )
    new_image.write(thumbnail_file)
  
    # Slide
    new_image = image.resize_to_fit(Catalog.default.max_slide_dimension, Catalog.default.max_slide_dimension )
    new_image.write(slide_file)
  
    # Display
    new_image = image.resize_to_fit(Catalog.default.max_display_dimension, Catalog.default.max_display_dimension )
    new_image.write(display_file)
    
    # Full
    new_image = image.resize_to_fit(Catalog.default.max_image_dimension, Catalog.default.max_image_dimension )
    new_image.write(full_file)

    image.destroy!
    new_image.destroy!
    full_file
  end
end
