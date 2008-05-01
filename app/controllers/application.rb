# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :set_publication
  before_filter :save_environment
  before_filter :adjust_format_for_iphone 
  before_filter :set_timezone
  
  helper_method :iphone_user_agent?
  helper_method :render_to_string
  helper_method :sidebar, :sidebar_clear
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '48b39a42fb4d72f8cdda67e5e38315ff'
  
  include AuthenticatedSystem
  include SimpleSidebar
  helper SimpleSidebarHelper  
  
  layout :current_layout
  
  rescue_from do
    respond_to do |format|
      format.html do
         flash[:notice] = "Sorry, the page you requested could not be found."
         redirect_back_or_default('/')
      end
      format.xml {head :status => 404}
      format.js  {head :status => 404}
    end
  end
  
  def rescue_action(exception)
    case exception.class.name
    when "ActionController::RoutingError"
      flash[:notice] = "Sorry, the page you requested is unknown."
    else
      flash[:notice] = "An internal error '#{exception}' was detected.  We have been notified."
    end
    redirect_back_or_default('/')
  end
  
  def publication
    @publication
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
    @publication = Publication.find_by_domain(request.host) || Publication.find_by_default_publication(true)
    raise Hermes::NoPublicationFound, "Publication for '#{request.host}' not found and no default publication." unless @publication
  end
  
  def save_environment
    User.current_user = logged_in? ? current_user : nil
    User.environment = request.env
    Publication.current = @publication
  end
    
  def current_layout
    ["rss","xml","atom"].include?(params[:format]) ? nil : @publication.theme
  end
  
  def set_timezone
   unless logged_in?
     Time.zone = browser_timezone if browser_timezone
   end
  end
    
end
