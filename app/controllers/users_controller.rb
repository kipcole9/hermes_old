class UsersController < AssetsController

  def create
    cookies.delete :auth_token
    reset_session
    @user = User.new(params[:user])
    @user.save!
    self.current_user = @user
    flash[:notice] = "Thanks for signing up! Please edit your profile."
    redirect_to edit_user_url(@user)
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end
  
  def update
    params[:user].delete(:id)
    if @user.update_attributes(params[:user])
      flash[:notice] = "User information updated"
      redirect_back_or_default("/")
    else
      flash[:notice] = "User information could not be updated"
      render :action => "edit"
    end
  end
  
private

  def authorized?
    current_user.is_admin?
  end
    
end
