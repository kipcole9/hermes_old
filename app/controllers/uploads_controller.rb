class UploadsController < AssetsController
  skip_before_filter :verify_authenticity_token
  
  def image
    if request.env["CONTENT_TYPE"] == "image/jpg"
      puts "Image of size #{request.env["HTTP_CONTENT_LENGTH"]} was found."
    end
    head :status => 201
  end
  
end