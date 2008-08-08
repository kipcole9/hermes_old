require 'pingback_api'
require 'rest_client'
require 'hpricot'
require 'cgi'

class PingbackService < ActionWebService::Base
  web_service_api PingbackAPI

  PING_ERROR_CODE = {
    :unspecified                    => 0,
    :uri_source_does_not_exist      => 16,
    :uri_no_target_link             => 17,
    :uri_target_does_not_exist      => 32,
    :uri_cannot_be_target           => 33,
    :uri_already_registered         => 48,
    :access_denied                  => 49,
    :could_not_communicate_upstream => 50
  }
  
  HEADERS = {
    :accept       => "text/html",
    "User-Agent"   => "Mozilla/4.0 (compatible; Hermes Pingback Server 1.0; Macintosh OS X 5.4)"
  }

  def ping(sourceURI, targetURI)
    # Get the target page - its needs to be on this site
    # and it needs to be referenceable for a pingback.
    begin
      target_page = RestClient.get(targetURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise Hermes::PingbackError, {:code => PING_ERROR_CODE[:uri_target_does_not_exist], :text => "TargetURI does not exist"}
    end
          
    # Source pages contains the link to us.      
    begin  
      source_page = RestClient.get(sourceURI, HEADERS)
    rescue RestClient::ResourceNotFound => e
      raise Hermes::PingbackError, {:code => PING_ERROR_CODE[:uri_source_does_not_exist], :text => "SourceURI does not exist"}
    end
    
    # Look for a link in the source_page that points to the target_page
    body = Hpricot(source_page)
    (body/"a").each do |a_link|
      if a_link.attributes["href"] == targetURI
        # Do something
        return "pingback accepted"
      end
    end
    raise Hermes::PingbackError, {:code => PING_ERROR_CODE[:uri_no_target_link], :text => "No target link"}
    
    # Unknown error
    rescue RestClient::RequestFailed => e
      puts "Some unknown error #{e} found"
      raise Hermes::PingbackError, {:code => PING_ERROR_CODE[:unspecified], :text => "Unmanaged error '#{e}'"}
  end

end
