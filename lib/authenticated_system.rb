module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      current_user != User.anonymous
    end
    
    # Accesses the current user from the session.  Set it to :false if login fails
    # so that future calls do not hit the database.
    def current_user
      @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || User.anonymous)
    end
    
    # Store the given user in the session and in the User object -> used by security_system.
    def current_user=(new_user)
      session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
      @current_user = new_user
      User.current_user = @current_user
    end
    
    # Check if the user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_user.login != "bob"
    #  end
    def authorized?
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |accepts|
        accepts.html do
          page_not_found
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Couldn't authenticate you", :status => '401 Unauthorized'
        end
        accepts.rss do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Couldn't authenticate you", :status => '401 Unauthorized'
        end
        accepts.atom do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Couldn't authenticate you", :status => '401 Unauthorized'
        end        
      end
      false
    end  
    
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end
    
    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default, options = {})
      session[:return_to] ? redirect_to(session[:return_to], options) : redirect_to(default, options)
      session[:return_to] = nil
    end
    
    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?
    end

    # Called from #current_user.  First attempt to login by the user id stored in the session.
    # User_id = 0 is the anonymous user (ie. no logged in, but represents the security profile)
    def login_from_session
      self.current_user = User.find_by_id(session[:user]) if session[:user] && session[:user] != 0
    end

    # Called from #current_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      username, passwd = get_auth_data
      self.current_user = User.authenticate(username, passwd) if username && passwd
    end

    # Called from #current_user.  Finally, attempt to login by an expiring token in the cookie.
    def login_from_cookie      
      user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        user.remember_me
        cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
        self.current_user = user
      end
    end
    
    # Do something as the Admin user (which has more access by default)
    # Use rarely.  Mainly used when we register a new user and we update the user to be
    # 'created_by' that user.
    def sudo
      if block_given?
        saved_user = self.current_user
        self.current_user = User.admin
        yield
        self.current_user = saved_user
      end
    end

  private
    @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
    # gets BASIC auth info
    def get_auth_data
      auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
      auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
      return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
    end
end
