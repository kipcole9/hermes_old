class Bookmark < ActiveRecord::Base
  acts_as_polymorph
  acts_as_polymorph_taggable  
  acts_as_secure
  
  require 'net/http'
  require 'uri'
  require 'hpricot'

  before_save :check_url_and_title
  
  def url=(val)
    super(URI.escape(val))
  end

private
  def check_url_and_title
    begin
      response = Net::HTTP.get_response(URI.parse(self.url)) if self.url
    rescue
      logger.error "Bookmark: Net::HTTP thinks '#{self.url}' is a bad url"
      self.errors.add("url", "appears to be bad")
      return false unless self.ignore_url_errors
    end
    
    if response
      self.http_response_code = response.code
      if !ignore_url_errors && response.code != "200" then
        self.errors.add("HTTP", "response code #{response.code} checking url.")
        return false
      end
    
      # Update our title to the title of the page
      body = Hpricot(response.body)
      title = (body/"title").inner_html
      self.title ||= title
    end
    true
  end
  
end