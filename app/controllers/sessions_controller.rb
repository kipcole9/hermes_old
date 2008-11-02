# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  #ssl_required          :new, :create
  skip_before_filter    :verify_authenticity_token, :only => :create
  
  def new
    #authenticate_or_request_with_http_basic do |username, passwd|
    #    params[:login] = username
    #    params[:password] = passwd
    #    create
    #end
  end

  def create
    if using_open_id?
      open_id_authentication(params[:openid_url])
    else
      password_authentication(params[:login], params[:password])
    end
  end

  def destroy
    person_logging_out = self.current_user.login
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "'#{person_logging_out}' has logged out."
    redirect_back_or_default('/')
  end
  
protected
  
  def open_id_authentication(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :email]) do |result, identity_url, registration|
      if result.successful?
        @user = User.find_or_initialize_by_identity_url(identity_url)
        if @user.new_record?
          @user.login = registration['nickname']
          @user.email = registration['email']
          @user.save(false)
        end
        self.current_user = @user
        successful_login
      else
        failed_login result.message
      end
    end
  end
  
  def password_authentication(login, password)
    self.current_user = User.authenticate(login, password)
    if logged_in?
      successful_login
    else
      failed_login
    end
  end
  
  def failed_login(message = "Invalid login credentials, please try again.")
    flash[:notice] = message
    render :action => 'new'
  end
  
  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token, 
        :expires => self.current_user.remember_token_expires_at }
    end
    flash[:notice] = "'#{self.current_user.login}' logged in successfully"
    redirect_back_or_default('/')
  end
  
  def using_open_id?
    !params[:openid_url].blank?
  end
end
