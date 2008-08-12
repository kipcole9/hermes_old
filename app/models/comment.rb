class Comment < ActiveRecord::Base
  belongs_to                    :asset
  belongs_to                    :created_by, :class_name => 'User', :foreign_key => "created_by"
  before_validation_on_create   :set_comment_status
  before_save                   :set_ip_address
  
  validates_presence_of   :asset
  validate do |comment|
    comment.check_content
  end
  
  named_scope :published, lambda { {:conditions => ["status = ?", Asset::STATUS[:published]]} }
  named_scope :not_spam, lambda { {:conditions => "spam = 0" } }
  named_scope :draft, lambda { {:conditions => ["status = ?", Asset::STATUS[:draft]]} }
  
  # Defensio spam protection service attributes
  def author_name
    if created_by
      created_by.full_name
    else
      created_by_name
    end
  end
  
  def author_email
    if created_by
      created_by.email
    else
      created_by_email
    end
  end
  
  def source
    "comment"
  end
  
  def user_ip
    User.ip_address
  end
  
  def check_content
    unless self.created_by
      errors.add_to_base("Must provide a name and email address") if created_by_name.blank? || created_by_email.blank?
    end
    errors.add_to_base("Valid email address is required") unless author_email.is_email?
    errors.add_to_base("Empty comments are not saved") if content.blank?
  end

private  
  def set_comment_status
    if Publication.current.moderate_comments && self.status.nil?
      self.status = Asset::STATUS[:draft]
    end
  end
  
  def set_ip_address
    self.ip_address = User.environment["IP"]
  end

end



