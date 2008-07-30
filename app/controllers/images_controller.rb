class ImagesController < AssetsController
  skip_before_filter    :verify_authenticity_token, :only => :update

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
      is_new ? head(:status => 201, :location => image_url(image, {})) : head(:status => 204)
    else
      image.errors.add("Name", "is '#{image.name}'")
      image.errors.add("Title", "is '#{image.title}'")
      render :status => 422, :xml => image.errors.to_xml
    end
  end
  
  def show_jpg
    if @image
      render :status => 200, :text => @image.updated_at.utc.iso8601
    else
      head :status => 404
    end
  end

  def random
    respond_to do |format|
      format.html
      format.js do
        render :partial => "sidebars/image_random.html.erb", :locals => {:ajax => true}
      end
    end
  end

  def page_size
    12
  end
  
  # called via Ajax
  def live_search
    if !params[:tags].blank?
      @images = Image.viewable_by(current_user).find_tagged_with(params[:tags])
    else
      @images = []
    end
    render :partial => "live_search", :locals => {:images => @images}
  end

  def recent
    @images = Image.published_in(publication).published.viewable_by(current_user) \
      .order('created_at DESC').limit(30).pager(unescape(params[:tags]), params[:page], page_size)
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
      .order('view_count DESC').limit(30).pager(unescape(params[:tags]), params[:page], page_size)
    @heading = "Popular Image Index"
    respond_to do |format|
      format.html {render :action => :index}
      format.rss
      format.atom
      format.xml
    end
  end
  
  def roulette
    @images = Image.published_in(publication).published.viewable_by(current_user) \
      .order('rand()').limit(30).pager(unescape(params[:tags]), params[:page], page_size)
    @heading = "Random Image Index"
    respond_to do |format|
      format.html {render :action => :index}
      format.rss
      format.atom
      format.xml
    end
  end
  
  def serve
    if splits = params[:id].match(/(.+)-(thumbnail|slide|display|full)$/)
      image_name = splits[1]
      image_type = splits[2]
    else
      image_name = params[:id]
      image_type = "full"
    end
    
    if image = Image.published_in(publication).published.viewable_by(current_user).find_by_name(image_name)
      path_name = image.send("#{image_type}_path_name")
    end
    
    if path_name
      minTime = Time.rfc2822(request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
      if minTime and image.updated_at <= minTime
        # use cached version
        head :status => 304
      else
        headers['Content-Description'] = params[:id]
        headers['Last-Modified'] = image.updated_at.httpdate
        expires_in 10.years, :private => false
        
        # Mongrel dones't support x-sendfile, and thats what we use in development
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

protected
  
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
