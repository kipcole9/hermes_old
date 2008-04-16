# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :set_publication
  before_filter :save_environment

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '48b39a42fb4d72f8cdda67e5e38315ff'
  
  include AuthenticatedSystem
  include SimpleSidebar
  helper SimpleSidebarHelper  
  
  layout :current_layout
  
  def set_publication
    # Publications are determined by the name of the host by which we were requested
    # If there is no such publication then use the default
    @publication = Publication.find_by_domain(request.host) || Publication.find_by_default_publication(true)
    raise Hermes::NoPublicationFound unless @publication
  end
  
  def save_environment
    User.current_user = logged_in? ? current_user : nil
    User.environment = request.env
    Publication.current_publication = @publication
  end
    
  def publication
    @publication
  end
  
  def current_layout
    ["rss","xml","atom"].include?(params[:format]) ? nil : @publication.theme
  end
    
end
