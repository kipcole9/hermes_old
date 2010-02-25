class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new registration'
    @body[:url]  = activate_url(:host => User.environment["HOST_WITH_PORT"],
                                :protocol => User.environment["PROTOCOL"],
                                :activation_code => user.activation_code)
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your registration has been activated!'
    @body[:url]  = root_url(:host => User.environment["HOST_WITH_PORT"],
                            :protocol => User.environment["PROTOCOL"])
  end
  
  protected
    def setup_email(user)
      @recipients  = user.email
      @from        = Publication.current.admin_email.blank? ? User.admin.email : Publication.current.admin_email
      @subject     = Publication.current.title + ": "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
