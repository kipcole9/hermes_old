class Image < ActiveRecord::Base
  include Hermes::Image::Metadata::Import
  include ActionController::UrlWriter
  acts_as_polymorph
  acts_as_polymorph_taggable
  acts_as_secure
  acts_as_hermes
  acts_as_mappable  :default_units => :kms, 
                    :lat_column_name => 'latitude', :lng_column_name => 'longitude', 
                    :delegate => :asset
  
  named_scope       :portrait,      :conditions => "orientation = 'p'"
  named_scope       :landscape,     :conditions => "orientation = 'l'"
  named_scope       :square,        :conditions => "orientation = 's'"
  named_scope       :any

  has_many          :slides,        :order => "position"
  has_many          :galleries,     :through => :slides
  belongs_to        :catalog
  
  before_validation_on_create :make_title
  skip_time_zone_conversion_for_attributes = [:taken_at]

  TAG_CLOUD_LIMIT   = 30
  ITEM_LIMIT        = 100

  def self.find_by_name_or_filename(name)
    find :first, :conditions => ["#{polymorph_table_name}.name = ? OR filename = ?", name, name]
  end
  
  def self.random(current_user, publication, orient = :any, num = 1)
    return nil unless publication && current_user
    case orient
    when :portrait
      results = viewable(current_user, publication).portrait.find(:all, :limit => num, :order => "rand()")
    when :landscape
      results = viewable(current_user, publication).landscape.find(:all, :limit => num, :order => "rand()")
    when :square
      results = viewable(current_user, publication).square.find(:all, :limit => num, :order => "rand()")
    else
      results = viewable(current_user, publication).find(:all, :limit => num, :order => "rand()")
    end
    num == 1 ? results.first : results
  end
  
  def display_caption(len = 99999)
    (self.title || self.filename.remove_file_suffix.gsub(/-/," ")).truncate(len)
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
    @exif << {:heading => "Camera", :item => camera_model, :param => "camera_model"} unless camera_model.blank?
    @exif << {:heading => "Lens", :item => lens, :param => :lens} unless lens.blank?
    @exif << {:heading => "Focal Length", :item => focal_length, :param => :focal_length} unless focal_length.blank?
    @exif << {:heading => "Flash", :item => flash, :param => :flash}  unless flash.blank?
    return @exif
  end
  
  # Import an image into the Image catalog if the image has not been imported, or if has
  # been updated/edited since last import
  def self.import(file, options = {})
    options.symbolize_keys!
    if File.exist?(file) then
      image_filename = File.basename(file)
      unless image = find_by_filename(image_filename)
        image = Image.new
        image.filename = image_filename
        image.catalog = Catalog.default
        image.title = options[:title] if options[:title]
        image.folder = options[:folder].with_slash
      end
      if image.updated_at.nil? || (options[:file_mtime] && (options[:file_mtime].to_time.utc > image.updated_at.utc)) || options[:file_mtime].nil?
        make_image_files(file, options[:folder])
        image.import_metadata
        image.description = options[:description] if options[:description]
        image.tag_list = options[:tags] if options[:tags]
        image.geocode
      else
        logger.info "Image Import: '#{file}' already imported (and up-to-date)"
      end
      image
    else
      logger.info "Image Import: Requested Image file #{file} does not exist - not imported."
      return nil
    end
  end
  
  def self.tag_cloud(current_user)
    # Top tags sorted alphabetically by name
    return viewable_by(current_user).tag_counts(:all, :order => "count desc", :limit => TAG_CLOUD_LIMIT) \
      .sort{|a, b| a.name <=> b.name}
  end
  
  def url
    image_path(self)
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

protected
  
  def validate
    errors.add("Filename", "was not set") unless self.filename
    errors.add("Title", "was not set") unless self.title
    errors.add("Catalog", "could not be assigned") unless set_catalog
    errors.add("Orientation", "was not set") unless calculate_orientation
  end

private  
  
  def calculate_orientation
    if self.width && self.height
      self.orientation = self.width > self.height ? "l" : (self.height > self.width ? "p" : "s")
    end
  end
  
  def make_title
    return unless !self.title.blank? || self.filename
    self.title = self.title.blank? ? self.filename.remove_file_suffix.titleize : self.title
  end
  
  def set_catalog
    self.catalog ||= Catalog.default
  end
  
end
