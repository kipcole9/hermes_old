require 'pingback_api'
require 'rest_client'
require 'hpricot'
require 'cgi'

class PingbackService < ActionWebService::Base
  web_service_api PingbackAPI

  PING_ERROR_CODE = {
    :unspecified                    => 0,
    :source_does_not_exist          => 16,
    :no_target_link                 => 17,
    :target_does_not_exist          => 32,
    :uri_cannot_be_target           => 33,
    :uri_already_registered         => 48,
    :access_denied                  => 49,
    :could_not_communicate_upstream => 50
  }
  
  HEADERS = {
    :accept       => "text/html",
    :user_agent   => "Hermes/1.0 Pingback Server"
  }

  def ping(sourceURI, targetURI)
    # Get the target page - its needs to be on this site
    # and it needs to be referenceable for a pingback.
    begin
      uri = URI.parse(targetURI)
      params = path_parameters_from_path(uri.path)
      raise_error(:uri_cannot_be_target) unless uri.host == Publication.current.domain && pingback_is_allowed?(params)
      target_page = RestClient.get(targetURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise_error :target_does_not_exist
    end
          
    # Source pages contains the link to us.      
    begin  
      source_page = RestClient.get(sourceURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise_error :source_does_not_exist
    end
    
    # Look for a link in the source_page that points to the target_page
    body = Hpricot(source_page)
    (body/"a").each do |a_link|
      if a_link.attributes["href"] == targetURI
        return "pingback accepted" if add_pingback(params, targetURI, body)
        raise_error :could_not_communicate_upstream
      end
    end
    raise_error :no_target_link
    
  # Unknown http error
  rescue RestClient::RequestFailed => e
    raise_error :unspecified, "Unmanaged error '#{e}'"
    
  # Couldn't parse the targetURI
  rescue URI::InvalidURIError =>
    raise_error :uri_target_does_not_exist
  end

private
  def raise_error(error, text = nil)
    raise Hermes::PingbackError, {:code => PING_ERROR_CODE[error], :text => (text || error.to_message)}
  end
  
  def pingback_is_allowed?(params)
    true
  end
  
  def add_pingback(params, targetURI, html_body)
    true
  end

end
