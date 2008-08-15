class Publication < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  
  before_validation_on_create   :set_bit_id
  before_validation_on_create   :set_name
  validates_presence_of         :domain
  validates_uniqueness_of       :domain
  
  def self.default
    @@default ||= find(:first, :conditions => ["default_publication = ?", true])
  end
  
  def self.current
    @current_publication || raise(Hermes::NoPublicationFound, "No current publication set in Publication class.")
  end
  
  def self.current=(pub)
    @current_publication = pub
  end

private
  def set_name
    self.name = self.name.blank? ? self.title.remove_file_suffix.permalink : self.name 
  end
  
  def set_bit_id
    # Each new Publication has a bit_id that is 2 times the previous maximum.  The idea is that we
    # can then use this id as a bit mask in permissions fields. Since in MySql the maximum size
    # is constrained to 20 digits, this equates to 65 bits and hence the maximum size below.
    # This means we cannot host any more than 65 publications using this scheme.
    max = Publication.maximum(:bit_id)
    raise "Publication cannot be created: maximum number reached" if max == 18446744073709551615
    self.bit_id = max * 2
  end
end