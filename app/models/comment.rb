class Comment < ActiveRecord::Base
  belongs_to    :asset
  belongs_to    :created_by, :class_name => 'User', :foreign_key => "created_by"
  before_validation_on_create   :set_comment_status
  before_save                   :check_spam
  
  validates_presence_of   :asset
  validate do |comment|
    comment.check_content
  end
  
  has_finder :published, lambda { {:conditions => ["status = ?", Asset::STATUS["published"]]} }
  has_finder :draft, lambda { {:conditions => ["status = ?", Asset::STATUS["draft"]]} }
  
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
  
  def check_content
    unless self.created_by
      errors.add_to_base("Must provide a name and email address") if created_by_name.blank? || created_by_email.blank?
    end
    errors.add_to_base("Valid email address is required") unless author_email.is_email?
    errors.add_to_base("Empty comments are not saved") if content.blank?
  end

private  
  def set_comment_status
    if Publication.current_publication.moderate_comments
      self.status = Asset::STATUS["draft"]
    else
      self.status = Asset::STATUS["published"]
    end
  end
  
  def check_spam
    
  end

end



