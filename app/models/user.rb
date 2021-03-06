require 'digest/sha1'

class User < ActiveRecord::Base
  acts_as_polymorph
  acts_as_polymorph_taggable
  acts_as_secure
  acts_as_hermes
  before_validation_on_create     :set_name_and_title
  before_create                   :make_activation_code  
  before_create                   :set_groups
  before_save                     :encrypt_password, :set_photo  
  USERS_DIR                       = "Users"
  
  # The assets we created
  has_many    :my_assets, :class_name => 'Asset', :foreign_key => :created_by
  belongs_to  :photo,     :class_name => 'Image', :foreign_key => :photo
  
  # Virtual attribute for the unencrypted password
  attr_accessor             :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false

  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :identity_url, :show_profile, 
                  :birthday, :photo, :city, :display_theme, :latitude, :profile, :time_zone, :content_rating, 
                  :country, :given_name, :family_name, :locale, :longitude, :show_photo, :tag_list
  
  def to_param
    self.name
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    u && u.authenticated?(password) ? u : nil
  end
  
  def self.authenticate_and_set(login, password)
    self.current_user = authenticate(login, password)
  end
  
  def self.authorise_and_set(email)
    self.current_user = self.find_by_email(email)
  end
  
  def self.logged_in?
    self.current_user != self.anonymous
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  def activated?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end  

  def full_name
    name = [given_name, family_name].join(' ').strip
    name = login if name.blank?
    name
  end
  
  def time_zone
    tz = read_attribute(:time_zone)
    tz.blank? ? "UTC" : tz
  end
  
  # Set the photo directly, or if it is an uploaded file, defer until
  # save time.  This is because the file name we use is based upon the
  # login name of the User and we need make sure that is set before
  # we set the photo.
  def photo=(temp_file)
    if temp_file.is_a?(Image)
      super(temp_file)
    else
      @temp_photo_file = temp_file
    end
  end
  
  def is_admin?
    AssetPermission.is_admin?(self)
  end
  
  def self.admin
    raise Hermes::NoAdminUserDefined unless @admin_user ||= find_by_login("Admin")
    @admin_user
  end
  
  def self.anonymous
    raise Hermes::NoAnonymousUserDefined unless @anon_user ||= find_by_login("Anon")
    @anon_user
  end
  
  # set in before filter of ApplicationController
  def self.current_user
    @current_user || self.anonymous
  end
  
  def self.current_user=(user)
    @current_user = user
  end
  
  # set in before filter of ApplicationController
  def self.environment
    @environment
  end
  
  def self.environment=(env)
    @environment =  env
  end  
  
  def self.ip_address
    self.environment ? self.environment["IP"] : "127.0.0.1"
  end
  
protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end  
  
  def set_groups
    self.groups = (self.groups == 0 || self.groups.nil?) ? AssetPermission.default_user_groups : self.groups
  end
  
  def set_name_and_title
    self.name = self.title = self.login
  end
  
  def set_photo
    if @temp_photo_file
      user_photo_file_name = "#{RAILS_ROOT}/tmp/uploads/#{self.login}.jpg"
      content = @temp_photo_file.read
      f2 = File.open(user_photo_file_name,"wb")
      f2.write(content)
      f2.close
      self.photo = Image.import(user_photo_file_name, USERS_DIR)
    end
  end
  
end
