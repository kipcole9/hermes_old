module Hermes
  module Upload
    require 'rest_client'
    require 'cgi'
    
    def upload_image(filename, options = {})
      raise "File #{filename} was not found to import" unless File.exists?(filename)
      raise "Only Jpeg image uploads supported" unless File.extname(filename) == ".jpg"
      target_uri = HERMES_UPLOAD[:url]
      updated_at = update_time(filename, target_uri)
      if updated_at && updated_at >= File.mtime(filename)
        puts "File #{filename} has not been modified, skipping upload."
        return
      end
      params = {}
      filename_url = CGI.escape(File.basename(filename))
      params["folder"] = options[:folder] || File.basename(File.dirname(filename))
      params["file_mtime"] = File.mtime(filename).utc.iso8601
      uri = "#{target_uri.with_slash}images/#{filename_url}"
      url = uri + "?" + url_combine(params)
      result = RestClient.put url, File.read(filename), :content_type => "image/jpg", :user_agent => HERMES_UPLOAD[:user_agent]
    rescue RestClient::RequestFailed => e
      case e.http_code
      when 204
        puts "File #{filename} was replaced"
      when 422
        puts "File #{filename} could not be uploaded"
        puts e.message       
      else
        puts "File #{filename} returned code #{e.http_code}"
      end
    else
      puts "File #{filename} was uploaded"
    end
  
    def upload_gallery
    
    end
   
    def update_time(filename, target_uri)
      url = "#{target_uri.with_slash}images/#{CGI.escape(File.basename(filename))}"
      puts url
      result = RestClient.get(url, :user_agent => HERMES_UPLOAD[:user_agent])
      puts "#{result}"
      return result.to_time
    rescue RestClient::ResourceNotFound => e
      return nil
    end
     
    def url_combine(hash)
     params = []
     hash.each {|k, v| params << "#{CGI.escape(k)}=#{CGI.escape(v)}"}
     params.join('&')
    end
  end
end