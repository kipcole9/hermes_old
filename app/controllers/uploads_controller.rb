class UploadsController < AssetsController
  require 'cgi'
  prepend_before_filter :collect_filename
  skip_before_filter    :retrieve_assets, 
                        :retrieve_parent_assets, :create_asset, :set_sidebars,
                        :remember_location, :log_show

  skip_before_filter    :verify_authenticity_token
  
  def update
    respond_to do |format|
      format.jpg do
        head :status => 406 unless Mime::Type.lookup(request.env['CONTENT_TYPE']) == Mime::Type.lookup_by_extension(:jpg)
        tmp_file = "#{RAILS_ROOT}/tmp/uploads/#{collect_filename}"
        f = File.new(tmp_file, "w")
        f.syswrite(request.raw_post)
        f.close
    
        head :status => 502 unless image = Image.import(tmp_file, params)
        is_new = image.new_record?
        if image.save
          is_new ? head(:status => 201, :location => image_url(image)) : head(:status => 204)
        else
          render :status => 422, :xml => image.errors.to_xml
        end
      end
    end
  end
  
  def show
    if @image
      respond_to do |format|
        format.jpg { render :status => 200, :text => @image.updated_at.utc.iso8601 }
      end
    else
      head :status => 404
    end
  end
  
private
  def retrieve_this_asset
    if @object = Image.viewable_by(current_user).find_by_filename(collect_filename)
      @image = @object
      @asset = @image.asset
    end
  end
       
  def collect_filename
    @filename ||= CGI.unescape(File.basename("#{params[:id]}.#{params[:format]}"))
  end
  
  def authorized?
    case params[:action]
    when "update"
      if @object
        @object.can_update?(current_user)
      else
        AssetPermission.can_create?("Image", current_user)
      end
    else
      true
    end
  end
end