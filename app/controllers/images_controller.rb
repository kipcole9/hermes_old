class ImagesController < AssetsController
  skip_before_filter    :verify_authenticity_token, :only => :update

  def index_kml
    render :action => "index"
  end
  
  def show_kml
    if @image.mappable?
      render :action => "show"
    else
      head :status => 404
    end
  end
  
  def index_rs2
    render :action => "photofeed"
  end

  def update_jpg
    head :status => 406 unless Mime::Type.lookup(request.env['CONTENT_TYPE']) == Mime::Type.lookup_by_extension(:jpg)
    if RAILS_ENV == "development"
      tmp_file = "#{RAILS_ROOT}/tmp/uploads/#{collect_filename}"
    else
      tmp_file = "/u/apps/hermes/uploads/#{collect_filename}"
    end
    f = File.new(tmp_file, "w")
    f.syswrite(request.raw_post)
    f.close

    head :status => 502 unless image = Image.import(tmp_file, params)
    is_new = image.new_record?
    if image.save
      logger.info "Imported #{File.basename(tmp_file)}.  Update time is now #{image.updated_at}."
      is_new ? head(:status => 201, :location => image_url(image, {})) : head(:status => 204)
    else
      image.errors.add("Name", "is '#{image.name}'")
      image.errors.add("Title", "is '#{image.title}'")
      render :status => 422, :xml => image.errors.to_xml
    end
  end
  
  def show_jpg
    if request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"] == HERMES_IMAGE_UPLOADER_USER_AGENT
      # Image uploader is only interested to know if the image exists and its update time
      @image ? render(:status => 200, :text => @image.updated_at.utc.iso8601) : head(:status => 404)
    else
      # We're serving an image
      serve_image(params[:id])
    end
  end

  def random
    respond_to do |format|
      format.js do
        render :partial => "sidebars/image_random.html.erb", :locals => {:ajax => true}
      end
    end
  end
  
  def roulette
    respond_to do |format|
      format.html do
        @images = Image.published_in(publication).published.viewable_by(current_user) \
          .order('rand()').limit(9)
      end
    end
  end
  
  def random_slide
    @images = Image.published_in(publication).published.viewable_by(current_user) \
      .order('rand()').limit(1).find(:all, :conditions => ["images.id NOT IN (?)", params[:current]])
    render :partial => "slide", :locals => {:image => @images.first}
  end

  def page_size
    12
  end
  
  # called via Ajax
  def live_search
    if !params[:tags].blank?
      @images = Image.viewable_by(current_user).find_tagged_with(unescape(params[:tags]))
    else
      @images = []
    end
    render :partial => "live_search", :locals => {:images => @images}
  end

  def recent
    @images = Image.published_in(publication).published.viewable_by(current_user) \
      .order('created_at DESC').limit(30).tagged_with(unescape(params[:tags])).page(params[:page], page_size)
    @heading = "Recent Image Index"
    respond_to do |format|
      format.html {render :action => :index}
      format.rss
      format.atom
      format.xml
    end
  end

  def popular
    @images = Image.published_in(publication).published.viewable_by(current_user) \
      .order('view_count DESC').limit(30).tagged_with(unescape(params[:tags])).page(params[:page], page_size)
    @heading = "Popular Image Index"
    respond_to do |format|
      format.html {render :action => :index}
      format.rss
      format.atom
      format.xml
    end
  end

protected
  def ignore_not_found?(target_id, format)
    params[:format] == "jpg"
  end

  def serve_image(image_file)
    image_name, image_type = image_from_param(image_file)
    if image = Image.published_in(publication).published.viewable_by(current_user).find_by_name(image_name)
      @asset = image.asset    # So log show will work
      path_name = image.send("#{image_type}_path_name")
    end
    
    if path_name
      minTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
      if minTime and image.updated_at <= minTime
        # use cached version
        head :status => 304
      else
        headers['Content-Description'] = image_file
        headers['Last-Modified'] = image.updated_at.httpdate
        expires_in 10.years, :private => false
        
        # Mongrel dones't support x-sendfile, and thats what we use in development
        log_show
        if RAILS_ENV == "production"
          send_file path_name, :disposition => 'inline', :x_sendfile => true
        else
          send_file path_name, :disposition => 'inline'
        end
      end
    else
      head :status => 404
    end
  end

  def image_from_param(param)
    if splits = param.match(/(.+)-(thumbnail|slide|display|full)$/)
      image_name = splits[1]
      image_type = splits[2]
    else
      image_name = param
      image_type = "full"
    end
    return image_name, image_type
  end
  
  def retrieve_this_jpg
    if @object = Image.viewable_by(current_user).find_by_filename(collect_filename)
      @image = @object
      @asset = @image.asset
    end
  end

  def collect_filename
    @filename ||= CGI.unescape(File.basename("#{params[:id]}.#{params[:format]}"))
  end  
  
  def authorized?
    if params[:action] == "update"
      @object ? @object.can_update?(current_user) : AssetPermission.can_create?("Image", current_user)
    else
      super
    end
  end
end
