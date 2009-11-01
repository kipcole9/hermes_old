# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :massage_format
  before_filter :set_publication
  before_filter :set_theme
  before_filter :check_supported_browsers  
  before_filter :save_environment
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
  
  def rescue_action_in_public(exception)
    log_exception(exception) 
    case(exception.class.name)
    when 'ActionController::RoutingError', 'ActionController::UnknownAction', 'ActionView::MissingTemplate',
         'ActiveRecord::RecordNotFound':
      page_not_found         
    else
      render_error_page
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
      format.any  { head :status => 404 }
    end
  end

  def browser_not_supported
    render :template => "shared/browser_not_supported", :layout => false, :status => 404
  end


  def render_error_page(message = "Sorry, something unexpected happened and your request could not be completed (we have been notified).")
    @error_page = message
    respond_to do |format|
      format.html { render :template => "shared/error_page", :status => 500 }
      format.any  { head :status => 500 }
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
      ActiveSupport::TimeZone[-min.minutes]
    end
  end
  
protected
  def check_supported_browsers
    if browser_is_older_internet_explorer?
       respond_to do |format|
         format.html { browser_not_supported }  # No good if htmml requested
         format.any  {                       }  # But ok if other format requested
       end
    end
  end
  
  def browser_is_older_internet_explorer?
    request.user_agent && request.user_agent.match(/\AMozilla\/4.0 \(compatible; MSIE [456]/)
  end

  # Some old legacy pages had a .htm format so to preserve
  # links we reformat
  def massage_format
    if params[:format] && params[:format] == "htm"
      request.format = :html
    end
  end
 
  def ssl_required?
    RAILS_ENV == "production" ? super : false
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
