require 'digest/sha1'

class User < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  before_create :set_groups, :set_publication
  
  # The assets we created
  has_many    :my_assets, :class_name => 'Asset', :foreign_key => :created_by
  belongs_to  :photo, :class_name => 'Image', :foreign_key => :photo
  
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
  before_save               :encrypt_password, :set_asset_name
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :identity_url, :show_profile, 
                  :birthday, :photo, :city, :display_theme, :latitude, :profile, :time_zone, :content_rating, 
                  :country, :given_name, :family_name, :locale, :longitude, :show_photo, :tag_list
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
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

  def full_name
    [given_name, family_name].join(' ')
  end
  
  def is_admin?
    AssetPermission.is_admin?(self)
  end
  
  def self.admin
    User.find_by_login("Admin")
  end
  
  def self.anonymous
    User.find_by_login("Anon")
  end
  
  # set in before filter of ApplicationController
  def self.current_user
    @current_user
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
  
protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
  
  def set_asset_name
    self.name = self.login
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def set_groups
    self.groups ||= AssetPermission.default_user_groups
  end
  
  def set_publication
    if self.publications
      self.publications |= Publication.current_publication.bit_id
    else
      self.publications = Publication.current_publication.bit_id
    end
  end
end
