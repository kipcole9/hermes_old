class AssetsController < ApplicationController
  include Hermes::ControllerExtensions
  
  before_filter :set_time_zone
  before_filter :sidebar_clear
  before_filter :before_retrieve_object
  before_filter :retrieve_parent_assets
  before_filter :retrieve_this_asset, :only => [:edit, :update, :show, :destroy, :comments, :order]
  before_filter :retrieve_comments,   :only => [:comments]
  before_filter :login_required,      :only => [:new, :create, :edit, :show, :update, :destroy, :index, :comments]
  before_filter :retrieve_assets,     :only => [:index]
  before_filter :after_retrieve_object
  before_filter :create_asset,        :only => [:new]
  before_filter :remember_location,   :only => [:show, :index]
  
  after_filter  :log_show,            :only => [:show]
  
  ASSET_ACTIONS = ["live_search", "apis"]
  BOTS          = /(Googlebot|yahoo! slurp|msnbot|Twiceler|DotBot|friendfeed|MJ12bot|NetNewsWire|CCBot|Technoratibot|Shere Scout|Moreoverbot|BlogPulseLive)/i
  GIS_BROWSERS  = /GoogleEarth/i
  
  # Proxies: implement in concrete Asset sub-class as required
  # Normally nothing is required (the correct template will get rendered)
  # and the before filter will do the retrieval
  
  # GET
  def index
    respond_to do |format|
      format.html
      format.rss
      format.atom
      format.xml  { render :xml => @objects.to_xml }
      format.any  { send("index_#{params[:format]}") } if respond_to?("index_#{params[:format]}")
    end
  end

  def show
    if @object && stale?(:last_modified => @object.updated_at.utc, :etag => [@object, @object.comments.count])
      respond_to do |format|
        format.html { render :action => :edit unless File.exist?(view_path) }
        format.xml  { render :xml => @object.to_xml }
        format.any  { send("show_#{params[:format]}") } if respond_to?("show_#{params[:format]}") 
      end
    end
  end
  
  def new
    respond_to do |format|
      format.html { render :action => :edit unless File.exist?(view_path) }
    end
  end
  
  # POST
  def create
    respond_to do |format|
      format.html { create_html }
      format.xml  { create_xml  }
      format.any  { send("create_#{params[:format]}") } if respond_to?("create_#{params[:format]}")
    end
  end

  # PUT
  def update
    before_update_object
    respond_to do |format|
      format.html { update_html }
      format.xml  { update_xml  }
      format.any  { send("update_#{params[:format]}") } if respond_to?("update_#{params[:format]}")
    end
  end

  # Edit just renders a form - therefore only relevant to html requests
  def edit
    respond_to do |format|
      format.html
    end
  end
  
  # DELETE
  def destroy
    before_destroy_object
    respond_to do |format|
      format.html { destroy_html }
      format.xml  { destroy_xml  }
      format.any  { send("destroy_#{params[:format]}") } if respond_to?("destroy_#{params[:format]}")
    end
  end
  
  def comments
    respond_to do |format|
      format.html { comments_html }
      format.xml  { comments_xml  }
      format.rss  { comments_rss  }
      format.atom { comments_atom }
      format.any  { send("comments_#{params[:format]}") } if respond_to?("comments_#{params[:format]}")
    end  
  end
  
  # Ajax-based search
  def live_search
    unless params[:tags].blank?
      @assets = Asset.published_in(publication).published.viewable_by(current_user) \
          .included_in_index(current_user) \
          .order('assets.content_type').find_tagged_with(Tag.unsynonym(params[:tags]))
    else
      @assets = []
    end
    render :partial => "live_search"    
  end
  
  # Serve the api service discovery document
  def apis
    respond_to do |format|
      format.xml
    end
  end
  
  # Default page size.  Override in subclass as required.
  def page_size
    10
  end
  
protected
  
  def create_html    
    @object = asset_obj.new(params[param_name])
    update_parent_attributes
    before_create_object
    if @object.save
      flash[:notice] = "#{asset_obj.name} created successfully."
      redirect_back_or_default('/') if after_create_object(true)
    else
      flash.now[:error] = "Could not create #{asset_obj.name}."
      set_error_sidebar
      if after_create_object(false)
        @object = asset_obj.new(params[param_name])
        render :action => :edit
      end
    end
  end
  
  def create_xml
    @object = asset_obj.new(params[param_name])
    update_parent_attributes
    before_create
    if @object.save
      after_create_object(true)      
      head :status => 201, :location => polymorphic_url(@object)
    else
      after_create_object(false)
      render :status => 422, :xml => @object.errors.to_xml
    end
  end
    
  def update_html
    if @object.update_attributes(params[param_name])
      after_update_object(true)
      if request.xhr?
        send_ajax_update_response(true)
      else
        flash[:notice] = "#{asset_obj.name} updated successfully."
        redirect_back_or_default("/")
      end
    else
      after_update_object(false)
      if request.xhr?
        send_ajax_update_response(false)
      else
        flash.now[:error] = "Could not update #{asset_obj.name}."
        set_error_sidebar
        render :action => "edit"
      end
    end
  end

  def update_xml
    if @object.update_attributes(params[param_name])
      after_update_object(true)
      head :status => 200
    else
      after_update_object(false)
      render :status => 422, :xml => @object.errors.to_xml
    end         
  end
  
  def destroy_html
    if @object.destroy
      after_destroy_object(true)
      flash[:notice] = "#{asset_obj.name} deleted successfully."
    else
      flash[:error] = "Could not delete #{asset_obj.name}."
      set_error_sidebar
      after_destroy_object(false)
    end
    redirect_back_or_default("/")
  end
  
  def destroy_xml
    if @object.destroy
      after_destroy_object(true)
      head :status => 200
    else
      after_destroy_object(false)
      render :status => 422, :xml => @object.errors.to_xml
    end
  end
  
  def comments_html
  end
  
  def comments_xml
    render :xml => @object.comments
  end
  
  def comments_rss
    render :template => "comments/comments.rss.builder"
  end
  
  def comments_atom
    render :template => "comments/comments.atom.builder"
  end

  def authorized?
    # Unless specified, no actions can be called on this base class
    return false if self.class.name == "AssetsController" && !ASSET_ACTIONS.include?(params[:action])
    case params[:action]
    when "edit","update"
      @object.can_update?(current_user)
    when "destroy"
      @object.can_delete?(current_user)
    when "new", "create"
      AssetPermission.can_create?(asset_obj.class.name, current_user)
    when "index"
      true  # Override in subclass as required
    when "show"
      true
    when "comments"
      true
    else
      raise "Unknown action '#{params[:action]}' found in authorized?"
    end
  end
  
  # We might pass in lattitude and longitude which need reformatting
  def before_update_object
    if params[:latitude] && params[:longitude]
      params[param_name] ||= {}
      if params[:has_moved] == "yes"
        params[param_name][:latitude] = params[:latitude]
        params[param_name][:longitude] = params[:longitude]
        params[param_name][:geocode_method] = Asset::GEO_MANUAL
        params[param_name][:geocode_accuracy] = Google_geocode_accuracy.size - 1
      end
      params[param_name][:map_type] = params[:map_type]
      params[param_name][:map_zoom_level] = params[:zoom]
    end
  end
  
  # Prototype methods for callbacks
  def before_retrieve_object; end
  def after_retrieve_object(success = true); true; end
  def before_create_object; end
  def after_create_object(success = true); true; end
  def after_update_object(sucess = true); true; end
  def before_destroy_object; end
  def after_destroy_object(success = true); true; end
  def ignore_not_found?(target, format); false; end
  
private

  def send_ajax_update_response(status_ok)
    if status_ok
      render :text => "Update successful.", :status => 200
    else
      render :text => "Update failed.", :status => 422
    end
  end
  
  def create_asset
    @object = asset_obj.new
    instance_variable_set(instance_variable_singular, @object)
  end

  # Retrieve the asset relating to this request
  def retrieve_this_asset
    retrieve_asset(asset_obj, @object, params[:id])
  end
  
  # Make sure foreign keys are in place at create time
  def update_parent_attributes
    @object.asset.created_by = current_user if asset_obj.respond_to?("polymorph_class")
    @parent_attributes.each do |k, v|
      @object.send("#{k}=", v)
    end
  end
    
  # Check for params that end in "_id"
  def retrieve_parent_assets
    @parent_attributes = {}
    params.each do |k, v|
      if k.to_s =~ /(.*)_id$/
        parent_obj_name = "#{$1}".capitalize
        parent_obj = Object.const_get(parent_obj_name)
        parent_obj_attribute = parent_obj_name.downcase
        parent_obj_instance_variable = "@#{parent_obj_attribute}"
        retrieve_asset(parent_obj, parent_obj_instance_variable, v)
        @parent_attributes[parent_obj_attribute] = instance_variable_get(parent_obj_instance_variable)
      end
    end
  end
  
  # Retrieve a row from 'target_obj' that has id 'target_id' and store it in instance variable
  # 'instance_variable_singular'
  def retrieve_asset(target_obj, instance_variable, target_id)
    user = asset_obj.respond_to?("polymorph_class") ? current_user : nil
    if !(@object = target_obj.viewable(user, publication).find_by_name_or_id(target_id) rescue nil)
      respond_to do |format|
        format.html { page_not_found("#{target_obj.name} '#{target_id}' not found!") }
        format.xml  { head :status => 404 }
        format.any  { send("retrieve_this_#{params[:format]}") } if respond_to?("retrieve_this_#{params[:format]}")
      end unless ignore_not_found?(target_id, params[:format])
    else
      @asset = @object.asset if target_obj.respond_to?("polymorph_class")        
    end
    instance_variable_set(instance_variable_singular, @object)
  end  

  # Called from index action, invoke query parameters if any
  def retrieve_assets
    user = asset_obj.respond_to?("polymorph_class") ? current_user : nil
    @objects = asset_obj.viewable(user, publication) \
                  .conditions(marshall_params) \
                  .included_in_index(current_user) \
                  .tagged_with(unescape(params[:tags])) \
                  .category_of(unescape(params[:category])) \
                  .order('assets.created_at DESC') \
                  .page(params[:page], page_size)  
    if @objects.blank?
      respond_to do |format|
        format.html { flash[:error] = "#{class_name}: found no items!" }
        format.xml  { head :status => 404 }
      end
    end
    instance_variable_set(instance_variable_plural, @objects)
    true
  end
  
  def retrieve_comments
    @comments = @object.comments.published
  end
  
  # Log the view. Also increment view_count.  We do it this way to avoid changing the
  # updated_at column (which we use to mean update to metadata)
  def log_show
    if @asset and !is_search_bot?(request.env["HTTP_USER_AGENT"])
      respond_to do |format|
        format.html { log_asset_show("html") }
        format.xml  { log_asset_show("xml")  }
        format.kml  { log_asset_show("kml")  }
        
        # Note that GoogleEarth declares a user-agent when getting kml, but not getting jpg
        # So basically this won't work until that is fixed
        format.jpg  { log_asset_show("jpg") if is_gis_browser?(request.env["HTTP_USER_AGENT"])  }
        format.any  {                     }
      end
    end
  end
  
  def log_asset_show(format)
    AssetView.log(publication.id, @asset, current_user, request.env["HTTP_USER_AGENT"], User.environment["IP"], request.env["HTTP_REFERER"], format)
    Asset.increment_view_count(@asset.attributes["id"]) 
  end
  
  def is_search_bot?(agent)
    agent && agent.match(BOTS)
  end
  
  def is_gis_browser?(agent)
    agent && agent.match(GIS_BROWSERS)
  end
    
  def remember_location
    respond_to do |format|
      format.html { store_location }
      format.any  {                }
    end
  end
  
  def set_time_zone
    Time.zone = current_user.time_zone
  end
  
end
