# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :set_publication
  before_filter :set_theme
  before_filter :save_environment
  #before_filter :adjust_format_for_iphone 
  before_filter :set_timezone
  
  helper_method :iphone_user_agent?
  helper_method :render_to_string
  helper_method :sidebar, :sidebar_clear
  helper_method :publication
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '48b39a42fb4d72f8cdda67e5e38315ff'
  
  include SslRequirement
  include ExceptionLoggable
  include AuthenticatedSystem
  include SimpleSidebar
  helper SimpleSidebarHelper  
  
  # Rescue_from incompatible with AWS (weird cookie overflow exception)
  def rescue_action_in_public(exception)
    status = response_code_for_rescue(exception)
    render_optional_error_file status
    log_exception(exception) if status != :not_found
    case(exception)
    when ::ActionController::UnknownAction
      page_not_found
    else
      super
    end
  end

  # This is the fall through from the default path.  Rather than return empty pages
  # or error pages we use our standard page_not_found process
  def unrecognized?
    page_not_found
  end
  
  def page_not_found(message = "Sorry, the page you requested was not found.")
    @page_not_found = message
    respond_to do |format|
      format.html { render :template => "shared/page_not_found", :status => 404 }
      format.xml  { head :status => 404 }
      format.rss  { head :status => 404 }
      format.atom { head :status => 404 }
    end
  end
  
  def publication
    Publication.current
  end
  
  # The browsers give the # of minutes that a local time needs to add to
  # make it UTC, while TimeZone expects offsets in seconds to add to 
  # a UTC to make it local.
  def browser_timezone
    return nil if cookies[:tzoffset].blank?
    @browser_timezone ||= begin
      min = cookies[:tzoffset].to_i
      TimeZone[-min.minutes]
    end
  end
  
protected
 
  def ssl_required?
    RAILS_ENV == "production" ? super : false
  end

  def adjust_format_for_iphone 
    # Detect from iPhone user-agent 
    request.format = :iphone if iphone_user_agent?
  end 
  
  # Request from an iPhone or iPod touch? 
  # (Mobile Safari user agent) 
  def iphone_user_agent? 
    request.env["HTTP_USER_AGENT"] && 
    request.env["HTTP_USER_AGENT"][/(Mobile\/.+Safari)/] 
  end 
  
  def set_publication
    # Publications are determined by the name of the host by which we were requested
    # If there is no such publication then use the default
    Publication.current = Publication.find_by_domain(request.host) || Publication.find_by_default_publication(true)
    raise Hermes::NoPublicationFound, "Publication for '#{request.host}' not found and no default publication." \
      unless Publication.current
  end
  
  def set_theme
    prepend_view_path "#{RAILS_ROOT}/vendor/themes/#{publication.theme}" if publication.theme
  end
  
  def save_environment
    User.current_user = logged_in? ? current_user : nil
    User.environment = request.env
    User.environment["HOST_WITH_PORT"] = request.host_with_port
    User.environment["HOST"] = request.host
    User.environment["PROTOCOL"] = request.protocol
    User.environment["IP"] = request.env["HTTP_X_REAL_IP"] || request.remote_addr || request.remote_ip
    Publication.current = publication
  end

  def set_timezone
   unless logged_in?
     Time.zone = browser_timezone if browser_timezone
   end
  end
    
end
