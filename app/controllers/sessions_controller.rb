# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  ssl_required :new, :create
  
  def new
    #authenticate_or_request_with_http_basic do |username, passwd|
    #    params[:login] = username
    #    params[:password] = passwd
    #    create
    #end
  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token, 
          :expires => self.current_user.remember_token_expires_at }
      end
      flash[:notice] = "'#{self.current_user.login}' logged in successfully"
      redirect_back_or_default('/')
    else
      flash[:notice] = "Invalid login credentials, please try again."
      render :action => 'new'
    end
  end

  def destroy
    login = self.current_user.login
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "'#{login}' has logged out."
    redirect_back_or_default('/')
  end
end
