require 'pingback_api'

class PingbackService < ActionWebService::Base
  web_service_api PingbackAPI

  def initialize
    @error_codes = {
      :unspecified => 0,
      :uri_not_exist => 16,
      :uri_not_target_link => 17,
      :uri_target_not_exist => 32,
      :uri_cannot_be_target => 33,
      :uri_already_registered => 48,
      :access_denied => 49,
      :could_not_communicate_upstream => 50
    }
  end

  def ping(sourceURI, targetURI)
    # sourceURI is requesting if targetURI on this site exists
    # Then we retrieve sourceURI and confirm there is a link to targetURI on the page
    # If so, then we log the pingback and save an abstract of the sourceURI
  end

end
