class UploadsController < AssetsController
  skip_before_filter :verify_authenticity_token
  
  def image
    if request.env["CONTENT_TYPE"] == "image/jpg"
      puts "Image of size #{request.env["HTTP_CONTENT_LENGTH"]} was found."
    else
      head :status => 501
    end
    
    tmp_file = "#{RAILS_ROOT}/tmp/uploads/#{params['filename']}"
    f = File.new(tmp_file, "w")
    f.syswrite(request.raw_post)
    f.close
    
    if image = Image.import(tmp_file, params)
      is_new = image.new_record?
      if image.save
        is_new ? head(:status => 201, :location => image_url(image)) : head(:status => 204)
      else
        render :status => 422, :xml => image.errors.to_xml
      end
    else
      head :status => 502
    end
  end
  
  def updated_at
    file = "#{params[:id]}.jpg"
    if image = Image.find_by_filename(file)
      render :status => 200, :text => image.updated_at.utc.iso8601
    else
      head :status => 404
    end
  end
  
end