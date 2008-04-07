class Asset < ActiveRecord::Base
  has_and_belongs_to_many     :categories 
  belongs_to                  :content, :polymorphic => true
  belongs_to                  :created_by, :class_name => 'User', :foreign_key => "created_by" 
  belongs_to                  :updated_by, :class_name => 'User', :foreign_key => "updated_by"
  has_many                    :comments  
  acts_as_taggable
  
  STATUS = AssetStatus.status_array
  
  before_save                 :set_permissions
  before_validation_on_create :set_name
  before_validation_on_create :set_created_by
  
  validates_presence_of     :name 
  validates_presence_of     :created_by
  validates_uniqueness_of   :name, :scope => :content_type
  validates_numericality_of :latitude, :allow_nil => true,
                            :greater_than => -90, :less_than => 90,
                            :message => "Must be a number between -90 and 90"
                            
  validates_numericality_of :longitude, :allow_nil => true,
                            :greater_than => -180, :less_than => 180,
                            :message => "Must be a number between -180 and 180"
  
  # Control finders that can be chained (they are really scope methods)
  # TODO DRY up this part with the one in acts_as_secure - especially the :published finder string
  has_finder :published_in, lambda {|publication| { :conditions => ["publications & ?", publication.bit_id] } }
  has_finder :order, lambda {|order| {:order => order} }
  has_finder :viewable_by, lambda { |user| 
    if user
      { :conditions => Asset.access_policy(user) }
    else
      nil
    end
  }   
  has_finder :published, lambda { {:conditions => Asset.published_policy} }
  
  # All scoping methods and has_finders leverage this access policy
  def self.access_policy(current_user)
    ["((assets.created_by = :user_id and assets.read_permissions & :owner_group) or (assets.read_permissions & :other_groups)) " + 
      "and (:user_content_rating >= assets.content_rating)",
      {:user_id => current_user.id,
      :owner_group => AssetPermission::GROUP["owner"],
      :other_groups => AssetPermission.non_owner_groups(current_user),
      :user_content_rating => current_user.content_rating} ]
  end
  
  def self.published_policy
    @published_policy ||= "(assets.dont_publish_before < now() OR assets.dont_publish_before IS NULL) "+
        "AND (assets.dont_publish_after > now() OR assets.dont_publish_after IS NULL) " +
        "AND (assets.status = #{Asset::STATUS["published"]})"
  end
  
  def can_update?(user)
    AssetPermission.can_update?(self, user)
  end
  
  def can_delete?(user)
    AssetPermission.can_delete(self.user)
  end

  def set_created_by(user)
    self.created_by ||= user
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
    rating = c.is_a?(Fixnum) ? ContentRating.find_by_rating(c) : ContentRating.find_by_name(c)
    if rating
      write_attribute(:content_rating, rating)
    else
      logger.warn("Asset: ContentRating: '#{c.to_s}' not found. Attribute not set.")
    end
  end
  
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
  def geocode(host = "localhost")
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
    
    if self.country && (self.latitude.blank? || self.longitude.blank? || self.google_geocoded?)
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
          puts "Asset: Address for '#{geocode_string}' unknown, trying with '#{geocode_new_string}'"
          results = Geocoding::get(geocode_new_string, :host => host)
          geocode_string = geocode_new_string
        end
      end
      
      if results.status == Geocoding::GEO_SUCCESS
        # puts "Geocoded '#{geocode_string}' with accuracy #{results[0].accuracy}"
        self.latitude = results[0].latitude
        self.longitude = results[0].longitude
        self.geocode_accuracy = results[0].accuracy
        self.google_geocoded = true
        self.save!
      else
        puts "Asset: Could not geocode '#{self.name}' with '#{geocode_string}'. Result was #{results.status}"
      end
    end
  end

private
  
  def set_permissions
    self.read_permissions   ||= AssetPermission.default_read_permission(self.class.name)
    self.update_permissions ||= AssetPermission.default_update_permission(self.class.name)
    self.delete_permissions ||= AssetPermission.default_delete_permission(self.class.name)
    self.content_rating     ||= ContentRating.default
  end
  
  def set_name
    self.name = self.name.blank? ? self.title.remove_file_suffix.permalink : self.name 
  end
  
  def set_created_by
    self.created_by ||= User.admin
  end
    
end