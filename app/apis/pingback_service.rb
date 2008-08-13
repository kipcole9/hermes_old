require 'pingback_api'
require 'rest_client'
require 'hpricot'
require 'cgi'
include HermesControllerExtensions

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
      raise_error(:uri_cannot_be_target, "Target '#{URI.parse(targetURI).host}' host is not this site #{Publication.current.domain}'.") unless URI.parse(targetURI).host == Publication.current.domain
      raise_error(:target_does_not_exist) unless asset = retrieve_asset_from_path(targetURI, User.anonymous, Publication.current)
      raise_error(:uri_cannot_be_target) unless asset.allow_pingbacks?
      target_page = RestClient.get(targetURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise_error(:target_does_not_exist)
    rescue Hermes::BadPingUri => e
      raise_error(:uri_cannot_be_target)  
    end
          
    # Source pages contains the link to us.      
    begin  
      source_page = RestClient.get(sourceURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise_error(:source_does_not_exist)
    end
    
    # Look for a link in the source_page that points to the target_page
    body = Hpricot(source_page)
    (body/"a").each do |a_link|
      if a_link.attributes["href"] == targetURI
        return "pingback accepted" if asset.add_pingback(sourceURI, body)
        raise_error(:could_not_communicate_upstream, "Couldn't register pingback")
      end
    end
    raise_error(:no_target_link)
    
  # Unknown http error
  rescue RestClient::RequestFailed => e
    raise_error(:unspecified, "Unexpected http error '#{e}'")
    
  # Couldn't parse the targetURI
  rescue URI::InvalidURIError
    raise_error(:uri_target_does_not_exist)
  end

private
  def raise_error(error, text = nil)
    raise Hermes::PingbackError, {:code => PING_ERROR_CODE[error], :text => (text || error.to_message)}
  end
  
end
