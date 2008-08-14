class Message < ActiveRecord::Base
  belongs_to                    :created_by, :class_name => 'User', :foreign_key => "created_by" 
  before_validation_on_create   :set_user
  before_save                   :set_ip_address
  validate do |comment|
    comment.check_content
  end


  def check_content
    unless self.created_by
      errors.add_to_base("Must provide a name") if created_by_name.blank?
      errors.add_to_base("Must provide an email address") if created_by_email.blank?
      errors.add_to_base("Valid email address is required") unless created_by_email && created_by_email.is_email?
    end
    errors.add_to_base("Empty messages are not sent") if self.content.blank?
  end
    
private
  
  def set_ip_address
    self.ip_address = User.environment["IP"]
    self.browser = User.environment["HTTP_USER_AGENT"]
  end
  
  def set_user
    self.created_by = User.current_user unless User.current_user == User.anonymous
  end
  

  
end