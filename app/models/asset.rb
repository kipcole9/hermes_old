class Asset < ActiveRecord::Base
  has_and_belongs_to_many     :categories 
  belongs_to                  :content, :polymorphic => true
  belongs_to                  :created_by, :class_name => 'User', :foreign_key => "created_by" 
  belongs_to                  :updated_by, :class_name => 'User', :foreign_key => "updated_by"
  has_many                    :comments, :dependent => :destroy
  has_many                    :asset_views, :dependent => :destroy
  
  acts_as_polymorph_asset     :accessors => [:tag_list, :category_ids, :category_names],  
                              :readers => [:comments_open?, :comments_closed?, :comments_none?, :comments_require_login?,
                                           :moderate_comments?, :status_description, :content_rating_description,
                                           :mappable?, :geocode, :asset_id, :comments,
                                           :permissions, :include_in_index?, :allow_pingbacks?, :view_count],
                              :to_xml =>  [:name, :title, :latitude, :longitude, :tag_list, :category_names, :content_rating,
                                           :description, :created_at, :updated_at, :created_by_email]   
  acts_as_mappable            :default_units => :kms, :lat_column_name => 'latitude', :lng_column_name => 'longitude'
  acts_as_taggable
  
  STATUS                      = AssetStatus.status_array
  ALLOW_COMMENTS              = {"none" => 0, "open" => 1, "closed" => 2}
  LAT                         = /\A([-+]?\d{1,2})[d°°] *(\d{1,2})[′\'] *(\d{1,2}\.?\d{0,4})[″\"] *(N|S)\Z/i
  LNG                         = /\A([-+]?\d{1,3})[d°°] *(\d{1,2})[′\'] *(\d{1,2}\.?\d{0,4})[″\"] *(E|W)\Z/i
  DECIMAL                     = /\A[-+]?[0-9]*\.?[0-9]+\Z/
  GEO_GOOGLE                  = 1
  GEO_GPS                     = 2
  GEO_MANUAL                  = 3
  
  before_save                 :set_permissions, :set_allow_comments, :set_publication, :set_status, :geocode
  before_validation_on_create :set_name
  before_validation_on_create :set_default_created_by
  
  validates_presence_of     :name 
  validates_presence_of     :created_by
  validates_presence_of     :title
  validates_uniqueness_of   :name, :scope => :content_type, :message => 'already taken'
  validates_numericality_of :map_zoom_level, :allow_nil => true
  validates_numericality_of :latitude, :allow_nil => true,
                            :greater_than => -90, :less_than => 90,
                            :message => "must be a number between -90 and 90"
                            
  validates_numericality_of :longitude, :allow_nil => true,
                            :greater_than => -180, :less_than => 180,
                            :message => "must be a number between -180 and 180"
                            
  validates_numericality_of :content_rating, :allow_nil => true,
                            :message => "must be an integer"
                          
  
  # Control finders that can be chained (they are really scope methods)
  # TODO DRY up this part with the one in acts_as_secure - especially the :published scope
  named_scope :published_in, lambda {|publication| { :conditions => ["publications & ?", publication.bit_id] } }
  named_scope :order, lambda {|order| {:order => order} }
  named_scope :viewable_by, lambda { |user| 
    if user
      { :conditions => Asset.access_policy(user) }
    else
      { :conditions => Asset.access_policy(User.anonymous) }
    end
  }
  named_scope :published, lambda { {:conditions => Asset.published_policy} }
  named_scope :included_in_index, lambda { |*user|
    (user.first && user.first.is_admin?) ? {:conditions => "include_in_index = 1"} : { }
  }
  named_scope :mappable,   { :conditions => '(latitude IS NOT NULL AND latitude <> 0) AND (longitude IS NOT NULL AND longitude <> 0)' } 
  named_scope :popular,    lambda {|num|   {:order => "view_count DESC", :limit => num} }
  named_scope :unpopular,  lambda {|num|   {:order => "created_at ASC", :limit => num}  }
  named_scope :recent,     lambda {|num|   {:order => "created_at DESC", :limit => num} }
  named_scope :conditions, lambda {|where| { :conditions => where } }
  named_scope :limit,      lambda {|limit| { :limit => limit } }
  named_scope :published_in, lambda {|publication| 
    { :conditions => ["publications & ?", publication.bit_id] }
  }
  named_scope :category_of, lambda {|*cat| 
    if cat && cat.first
      {:conditions => "#{table_name}.id in (select #{table_name}.id \
          from assets join assets_categories on #{polymorph_table_name}.id = assets_categories.asset_id \
              join categories on categories.id = assets_categories.category_id \
              where categories.name = '#{cat.first}')" }
    else
      { }
    end
  }

  # All scoping methods and named_scopes leverage this access policy
  def self.access_policy(current_user)
    raise(Hermes::NoCurrentUser, "No Current User defined") unless current_user
    ["((assets.created_by = :user_id AND assets.read_permissions & :owner_group) " +
      "OR (assets.read_permissions & :other_groups)) " + 
      "AND (:user_content_rating >= assets.content_rating)",
      {:user_id => current_user.id,
      :owner_group => AssetPermission::GROUP["owner"],
      :other_groups => AssetPermission.non_owner_groups(current_user),
      :user_content_rating => current_user.content_rating} ]
  end
  
  def self.published_policy
    @published_policy ||= "(assets.dont_publish_before < now() OR assets.dont_publish_before IS NULL) "+
        "AND (assets.dont_publish_after > now() OR assets.dont_publish_after IS NULL) " +
        "AND (assets.status = #{Asset::STATUS[:published]})"
  end
  
  def latitude=(lat)
    if lat.is_a?(String) && lat_decimal = lat.match(LAT)
      latitude_decimal = (lat_decimal[1].to_f + (lat_decimal[2].to_f / 60) + (lat_decimal[3].to_f / 3600)) * ((lat_decimal[4].downcase == "n") ? 1.0 : -1.0)
      super(latitude_decimal)
    else
      super(lat)
    end
  end
  
  def longitude=(lng)
    if lng.is_a?(String) && lng_decimal = lng.match(LNG)
      longitude_decimal = (lng_decimal[1].to_f + (lng_decimal[2].to_f / 60) + (lng_decimal[3].to_f / 3600)) * ((lng_decimal[4].downcase == "e") ? 1.0 : -1.0)
      super(longitude_decimal)
    else
      super(lng)
    end
  end

  # Comments flags
  def moderate_comments?
    Publication.current.moderate_comments || attributes['moderate_comments']
  end
  
  def comments_open?
    Publication.current.allow_comments == ALLOW_COMMENTS["open"] && 
      attributes['allow_comments'] == ALLOW_COMMENTS["open"]
  end
  
  def comments_closed?
    Publication.current.allow_comments == ALLOW_COMMENTS["closed"] || 
      attributes['allow_comments'] == ALLOW_COMMENTS["closed"]
  end            
  
  def comments_none?              
    Publication.current.allow_comments == ALLOW_COMMENTS["none"] || 
      attributes['allow_comments'] == ALLOW_COMMENTS["none"]
  end
  
  def comments_require_login?
    Publication.current.comments_require_login || attributes['comments_require_login']
  end
  
  def allow_pingbacks?
    Publication.current.allow_pingbacks && attributes['allow_pingbacks']
  end
  
  # Authorisation methods
  def can_update?(user)
    AssetPermission.can_update?(self, user)
  end
  
  def can_delete?(user)
    AssetPermission.can_delete?(self, user)
  end
  
  def mappable?
    self.latitude && self.longitude
  end
  
  def self.increment_view_count(id)
    sql = ActiveRecord::Base.connection();
    sql.update "UPDATE assets SET view_count = view_count + 1 WHERE id=#{id}"
  end
  
  # Find the most recent updated_at for a content type
  # Used to define the update time for feeds (atom, rss, ...)
  def self.last_updated(content_type)
    asset_type = content_type.name if content_type.is_a?(Class)
    asset_type = content_type if content_type.is_a?(String)
    asset_type = content_type.class.name if content_type.class.respond_to?("descends_from_active_record?")
    raise ArgumentError unless asset_type
    maximum(:updated_at, :conditions => ["content_type = ?", asset_type])
  end
  
  def content_rating=(c)
    return if c.blank?
    content_rating = ContentRating.find_by_rating(c) || ContentRating.find_by_name(c)
    if content_rating
      write_attribute(:content_rating, content_rating.rating)
    else
      logger.warn("Asset: ContentRating: '#{c.to_s}' not found. Attribute not set.")
    end
  end
  
  def status=(s)
    unless s.nil?
      s.is_a?(Fixnum) || s.is_integer? ? super(s) : super(STATUS[s.to_sym])
    else
      super
    end
  end
  
  def content_rating_description
    ContentRating.find_by_rating(self.content_rating).name
  end
  
  def status_description
    STATUS.index(self.status).to_s
  end
  
  def created_by_email
    self.created_by.email
  end
  
  def created_by_email=(email)
    self.created_by = User.find_by_email(email)
  end
  
  def category_names
    self.categories.map(&:name).join(', ')
  end
  
  def category_names=(names)
    self.category_ids = names.split(',').map {|n| Category.find(:first, :conditions => ["name = ?", n.strip]).attributes['id'] rescue nil }.compact
  end
  
  # Convenience method to show human readable form of permissions for an object
  def permissions
    ["read_permissions", "update_permissions", "delete_permissions"].each do |p|
      perms = self.send(p)
      perm_string = []
      AssetPermission::GROUP.each do |g, v|
        if perms & AssetPermission::GROUP[g] > 0
          perm_string << g
        end
      end
      puts "#{self.name}: #{p}: #{perm_string.join(',')}"
    end
  end

  # Geocode the asset, using Google geocoding
  def geocode(host = nil)
    #  Data accuracy, as returned by google geocoder - think this relates to zoom level too for google maps
    #  0	 Unknown location. (Since 2.59)
    #  1	 Country level accuracy. (Since 2.59)
    #  2	 Region (state, province, prefecture, etc.) level accuracy. (Since 2.59)
    #  3	 Sub-region (county, municipality, etc.) level accuracy. (Since 2.59)
    #  4	 Town (city, village) level accuracy. (Since 2.59)
    #  5	 Post code (zip code) level accuracy. (Since 2.59)
    #  6	 Street level accuracy. (Since 2.59)
    #  7	 Intersection level accuracy. (Since 2.59)
    #  8	 Address level accuracy. (Since 2.59
    
    host ||= User.environment["HOST"] rescue "localhost"
    if self.country && !self.mappable?
      geocode_keys = []
      geocode_keys << self.location if self.location
      geocode_keys << self.city if self.city
      geocode_keys << self.state if self.state
      geocode_keys << self.country if self.country
      geocode_string = geocode_keys.join(", ")
      # puts "Geocoding '#{geocode_string}'"
      results = Geocoding::get(geocode_string, :host => host)
      if results.status == Geocoding::GEO_UNKNOWN_ADDRESS
        # Try with just city and country
        geocode_keys = []
        geocode_keys << self.city if self.city
        geocode_keys << self.country if self.country
        geocode_new_string = geocode_keys.join(", ")
        if geocode_new_string != geocode_string
          logger.info "Asset: Address for '#{geocode_string}' unknown, trying with '#{geocode_new_string}'"
          results = Geocoding::get(geocode_new_string, :host => host)
          geocode_string = geocode_new_string
        end
      end
      
      if results.status == Geocoding::GEO_SUCCESS
        # logger.info "Geocoded '#{geocode_string}' with accuracy #{results[0].accuracy}"
        self.latitude = results[0].latitude
        self.longitude = results[0].longitude
        self.geocode_accuracy = results[0].accuracy
        self.geocode_method = GEO_GOOGLE
      else
        logger.info "Asset: Could not geocode '#{self.name}' with '#{geocode_string}'. Result was #{results.status}"
      end
    end
    true
  end
  
  # Add location identifiers as tags
  def tag_list=(tags)
    location_tags = [self.location, self.city, self.state, self.country]
    new_tags = [location_tags, tags].flatten.compact.reject{|n| n.blank?}.uniq.join(', ')
    super new_tags
  end
  
private
  
  def set_permissions
    self.read_permissions   ||= AssetPermission.default_read_permission(self.class.name)
    self.update_permissions ||= AssetPermission.default_update_permission(self.class.name)
    self.delete_permissions ||= AssetPermission.default_delete_permission(self.class.name)
    self.content_rating     ||= ContentRating.default
  end
  
  def set_name
    if self.name.blank?
      self.name = self.title.remove_file_suffix.permalink unless self.title.blank?
    end
  end
  
  def set_default_created_by
    self.created_by ||= User.current_user
  end
  
  def set_allow_comments
    self.allow_comments ||= ALLOW_COMMENTS["open"]
  end
  
  def set_publication
    if self.publications
      self.publications |= Publication.current.bit_id
    else
      self.publications = Publication.current.bit_id
    end
  end
  
  def set_status
    self.status ||= STATUS[:published]
  end
end