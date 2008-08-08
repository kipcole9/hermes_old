class AssetsController < ApplicationController
  include HermesControllerExtensions
  
  before_filter :set_time_zone
  before_filter :sidebar_clear
  before_filter :before_retrieve
  before_filter :retrieve_parent_assets
  before_filter :retrieve_this_asset, :only => [:edit, :update, :show, :destroy]
  before_filter :login_required, :only => [:new, :create, :edit, :show, :update, :destroy, :index]
  before_filter :retrieve_assets, :only => [:index]
  before_filter :after_retrieve
  before_filter :create_asset, :only => [:new]
  before_filter :set_sidebars, :only => [:edit, :update, :show, :index]
  before_filter :remember_location, :only => [:show, :index]
  
  after_filter  :log_show, :only => [:show]
  @@asset_actions = ["live_search", "apis"]
  
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
    end
  end

  def show
    respond_to do |format|
      format.html { render :action => :edit if !File.exist?(view_path) }
      format.xml  { render :xml => @object.to_xml }
      format.any  { send("show_#{params[:format]}") } if respond_to?("show_#{params[:format]}")      
    end
  end
  
  def new
    respond_to do |format|
      format.html { render :action => :edit if !File.exist?(view_path) }
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
    before_update
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
  def destroy;
    respond_to do |format|
      format.html { destroy_html }
      format.xml  { destroy_xml  }
      format.any  { send("destroy_#{params[:format]}") } if respond_to?("destroy_#{params[:format]}")
    end
  end
  
  # Ajax-based search
  def live_search
    unless params[:tags].blank?
      @assets = Asset.published_in(publication).published.viewable_by(current_user) \
          .included_in_index(current_user) \
          .order('assets.content_type').find_tagged_with(params[:tags])
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
  
  # Generally implemented in a subclass
  def set_sidebars; end
  
  # Default page size.  Override in subclass as required.
  def page_size
    10
  end
  
protected
  
  def create_html    
    @object = asset_obj.new(params[param_name])
    update_parent_attributes
    before_create
    if @object.save
      flash[:notice] = "#{asset_obj.name} created successfully."
      redirect_back_or_default('/') if after_create(true)
    else
      flash[:now] = "Could not create #{asset_obj.name}"
      set_error_sidebar
      render :action => :edit if after_create(false)
    end
  end
  
  def create_xml
    @object = asset_obj.new(params[param_name])
    update_parent_attributes
    before_create
    if @object.save
      after_create(true)      
      head :status => 201, :location => polymorphic_url(@object)
    else
      after_create(false)
      render :status => 422, :xml => @object.errors.to_xml
    end
  end
    
  def update_html
    before_update
    if @object.update_attributes(params[param_name])
      after_update(true)
      flash[:notice] = "#{asset_obj.name} updated successfully."
      redirect_back_or_default("/")
    else
      set_error_sidebar
      after_update(false)
      render :action => "edit"
    end
  end

  def update_xml
    if @object.update_attributes(params[param_name])
      after_update(true)
      head :status => 200
    else
      after_update(false)
      render :status => 422, :xml => @object.errors.to_xml
    end         
  end
  
  def destroy_html
    before_destroy
    if @object.destroy
      after_destroy(true)
      flash[:notice] = "#{asset_obj.name} deleted successfully."
    else
      set_error_sidebar
      after_destroy(false)
    end
    redirect_back_or_default("/")
  end
  
  def destroy_xml
    before_destroy
    if @object.destroy
      after_destroy(true)
      head :status => 200
    else
      after_destroy(false)
      render :status => 422, :xml => @object.errors.to_xml
    end
  end

  def authorized?
    # Unless specified, no actions can be called on this base class
    return false if self.class.name == "AssetsController" && !@@asset_actions.include?(params[:action])
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
    else
      raise "Unknown action '#{params[:action]}' found in authorized?"
    end
  end
  
  # Prototype methods for callbacks
  def before_retrieve; end
  def after_retrieve(success = true); true; end
  def before_create; end
  def after_create(success = true); true; end
  def before_update; end
  def after_update(sucess = true); true; end
  def before_destroy; end
  def after_destroy(success = true); true; end
  
private
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
      if !(@object = target_obj.viewable_by(user).find_by_name_or_id(target_id) rescue nil)
        respond_to do |format|
          format.html do
            page_not_found("#{target_obj.name} '#{target_id}' not found!")
          end
          format.xml do
            head :status => 404
          end
          format.any do
            send("retrieve_this_#{params[:format]}")
          end if respond_to?("retrieve_this_#{params[:format]}")
        end
      else
        @asset = @object.asset if target_obj.respond_to?("polymorph_class")        
      end
      instance_variable_set(instance_variable_singular, @object)
    end  

    # Called from index action, invoke query parameters if any
    def retrieve_assets
      user = asset_obj.respond_to?("polymorph_class") ? current_user : nil
      @objects = asset_obj.viewable_by(user).conditions(marshall_params) \
                    .included_in_index(current_user) \
                    .with_category(params[:category]) \
                    .order('assets.created_at DESC') \
                    .pager(unescape(params[:tags]), params[:page], page_size)  
      if @objects.blank?
        respond_to do |format|
          format.html { flash[:notice] = "#{class_name}: found no items!" }
          format.xml  { head :status => 404 }
        end
      end
      instance_variable_set(instance_variable_plural, @objects)
      true
    end
   
    
    # Log the view. Also increment view_count.  We do it this way to avoid changing the
    # updated_at column (which we use to mean update to metadata)
    def log_show
      respond_to do |format|
        format.html { log_asset_show }
        format.xml  { log_asset_show }
        format.any  {                }
      end
    end
    
    def log_asset_show
      if @asset
        AssetView.log(publication.id, @asset, current_user, request.env["HTTP_USER_AGENT"], 
                    (request.env["HTTP_X_REAL_IP"] || request.remote_addr || request.remote_ip))
        Asset.increment_view_count(@asset.attributes["id"])
      end
    end
    
    def remember_location
      store_location
    end
    
    def set_time_zone
      Time.zone = current_user.time_zone
    end
    
end
