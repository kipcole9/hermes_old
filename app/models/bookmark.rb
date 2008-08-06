class Bookmark < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  
  require 'net/http'
  require 'uri'
  require 'hpricot'

  before_save :check_url_and_title

private
  def check_url_and_title
    begin
      response = Net::HTTP.get_response URI.parse(self.url)
    rescue URI::InvalidURIError
      logger.error "Bookmark: Net::HTTP thinks '#{self.url}' is a bad url"
      self.errors.add("url", "appears to be bad")
      return false
    end
    
    if response.code != "200" then
      return false
    end
    
    # Update our title to the title of the page
    body = Hpricot(response.body)
    title = (body/"title").inner_html
    self.title ||= title
    true
  end
  
end