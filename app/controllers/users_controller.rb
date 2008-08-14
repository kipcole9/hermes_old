class UsersController < AssetsController

  def after_create_object(success)
    # Update the owner of this record to be our new person
    if success
      sudo do
        @object.created_by = @object
        @object.save!
      end
      cookies.delete :auth_token
      reset_session
      flash[:notice] = "'#{@object.full_name}' is now registered but not activated. " + \
                       "Please check your email for activation instructions."
      return true
    else
      render :action => :new
    end
    false
  end

  def activate
    respond_to do |format|
      format.html do
        saved_current_user = current_user
        self.current_user = params[:activation_code].blank? ? User.anonymous : \
                            User.find_by_activation_code(params[:activation_code])
        if logged_in? && !current_user.activated?
          if current_user.activate
            flash[:notice] = "Signup complete!"
            redirect_back_or_default('/')        
          else
            flash[:notice] = "Activation could not be completed."
            logger.warn "Activation could not be completed"
            logger.warn "#{current_user.errors.inspect}"
            self.current_user = saved_current_user
            redirect_to root_url
          end
        else
          logger.warn "Activation: #{current_user.login} requested account activation with '#{params[:activation_code]}'"
          self.current_user = saved_current_user
          page_not_found
        end
      end
    end
  end  
  
protected

  def authorized?
    case action_name
    when "index" && !current_user.is_admin?
      false
    when "new", "create"
      true
    else
      super
    end
  end
    
end
