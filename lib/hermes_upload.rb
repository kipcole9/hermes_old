module HermesUpload
  require 'rest_client'
  require 'cgi'
   
  #URI = "http://kip:crater123@localhost:3000/"
  URI = "http://kip:crater123@www.noexpectations.com.au/"
    
  def upload_image(filename, folder = nil)
    raise "File #{filename} was not found to import" unless File.exists?(filename)
    raise "Only Jpeg image uploads supported" unless File.extname(filename) == ".jpg"
    updated_at = update_time(filename)
    if updated_at && updated_at >= File.mtime(filename)
      puts "File #{filename} has not been modified, skipping upload."
      return
    end
    params = {}
    filename_url = CGI.escape(File.basename(filename))
    params["folder"] = folder || File.basename(File.dirname(filename))
    params["file_mtime"] = File.mtime(filename).utc.iso8601
    uri = "#{URI}images/#{filename_url}"
    url = uri + "?" + url_combine(params)
    result = RestClient.put url, File.read(filename), :content_type => "image/jpg"
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
   
  def update_time(filename)
    url = "#{URI}images/#{CGI.escape(File.basename(filename))}"
    result = RestClient.get(url)
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