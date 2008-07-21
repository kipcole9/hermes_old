module HermesUpload
  require 'rest_client'
  require 'cgi'
   
  URI = "http://kip:crater123@localhost:3000/uploads/"
   
  def upload(filename, folder = nil)
    raise "File #{filename} was not found to import" unless File.exists?(filename)
    raise "Only Jpeg image uploads supported" unless File.extname(filename) == ".jpg"
    image_exists, updated_at = update_time(filename)
    if image_exists && updated_at >= File.mtime(filename)
      puts "File #{filename} has not been modified, skipping upload."
      return
    end
    params = {}
    params["filename"] = File.basename(filename)
    params["folder"] = folder || File.basename(File.dirname(filename))
    params["file_mtime"] = File.mtime(filename).utc.to_s
    uri = "#{URI}image"
    url = uri + "?" + url_combine(params)
    result = RestClient.put url, File.read(filename), :content_type => 'image/jpg'
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
   
  def update_time(filename)
    url = "#{URI}#{CGI.escape(File.basename(filename, ".*"))}/updated_at"
    result = RestClient.get(url)
    return true, result.to_time
  rescue RestClient::ResourceNotFound => e
    return false, nil
  end
     
  def url_combine(hash)
   params = []
   hash.each {|k, v| params << "#{CGI.escape(k)}=#{CGI.escape(v)}"}
   params.join('&')
  end
   
 end