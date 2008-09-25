class Comment < ActiveRecord::Base
  belongs_to                    :asset
  belongs_to                    :created_by, :class_name => 'User', :foreign_key => "created_by"
  before_validation_on_create   :set_comment_status
  before_create                 :set_ip_address, :set_comment_type, :defensio_spam_check
  
  validates_presence_of   :asset
  validate do |comment|
    comment.check_content
  end
  
  named_scope :draft, lambda { {:conditions => ["status = ?", Asset::STATUS[:draft]]} }
  named_scope :published, lambda { {:conditions => ["status = ?", Asset::STATUS[:published]]} }
  named_scope :not_spam, lambda { {:conditions => "spam = 0" } }
  named_scope :spam, lambda { {:conditions => "spam = 1" } }
  
  COMMENT_TYPE = {
    :comment    => "comment",
    :pingback   => "pingback",
    :trackback  => "trackback",
    :other      => "other"
  }
  
  def self.add_pingback(asset, sourceURI, body)
    comment = Comment.new(:asset => asset.asset, :comment_type => COMMENT_TYPE[:pingback],
                   :created_by => User.admin, :status => Asset::STATUS[:published],
                   :website => sourceURI, :content => self.pingback_comment(sourceURI, body))
    comment.save               
  end
  
  # Defensio spam protection service attributes
  def author_name
    created_by ? created_by.full_name : created_by_name
  end
  
  def author_email
    created_by ? created_by.email : created_by_email
  end
  
  def author_url
    created_by ? created_by.website : website
  end
  
  def source
    self.comment_type
  end
  
  def user_ip
    User.ip_address
  end
  
  def check_content
    unless self.created_by
      errors.add_to_base("Must provide a name") if created_by_name.blank?
      errors.add_to_base("Must provide an email address") if created_by_email.blank?
      errors.add_to_base("Valid email address is required") unless (created_by_email && created_by_email.is_email?) || comment_type == COMMENT_TYPE[:pingback]
    end
    errors.add_to_base("Empty comments are not saved") if content.blank?
  end

private
  def defensio_spam_check
    defensio = Defensio.new(:no_validate_key => true)
    article = self.asset.content
    if defensio.audit_comment(article, self)
      self.signature = defensio.response["signature"]
      self.spam = defensio.response["spam"]
      self.spaminess = defensio.response["spaminess"]
      self.status = self.spam? ? Asset::STATUS[:draft] : Asset::STATUS[:published]
    else
      logger.warning "Comment: Defensio failure: setting comment to draft"
      self.status = Asset::STATUS[:draft]
    end
    self.status = Asset::STATUS[:draft] if self.asset.moderate_comments?
  end 
    
  def set_comment_status
    if self.status.nil?
      self.status = Asset::STATUS[:draft]
    end
  end
  
  def set_ip_address
    self.ip_address = User.environment["IP"]
  end
  
  def set_comment_type
    self.comment_type ||= COMMENT_TYPE[:comment]
  end
  
  def self.pingback_comment(sourceURI, body)
    source_title = (body/'title').inner_html
    source_title = source_title.blank? ? 'site' : source_title
    "Pingback from \'<a href=\"#{sourceURI}\">#{source_title}\'.</a>"
  end
end



