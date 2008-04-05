class AssetsController < ApplicationController
  include HermesControllerExtensions
  before_filter :login_required, :only => [ :edit, :update, :new, :create, :destroy ]
  before_filter :before_retrieve
  before_filter :retrieve_parent_assets
  before_filter :retrieve_this_asset, :only => [:edit, :update, :show]
  before_filter :retrieve_assets, :only => [:index]
  before_filter :after_retrieve
  before_filter :create_asset, :only => [:new]
  before_filter :set_sidebars, :only => [:edit, :update, :show, :index]
  before_filter :remember_location, :only => [:show, :index]
  
  after_filter  :log_show, :only => [:show]
  
  # Proxies: implement in concrete Asset sub-class as required
  # Normally nothing is required (the correct template will get rendered)
  # and the before filter will do the retrieval
  def index

  end

  def show
    respond_to do |format|
      format.html { render :action => :edit if !File.exist?(view_path) }
      format.xml  { render :xml => @object.to_xml }
    end
  end
  
  def new
    respond_to do |format|
      format.html { render :action => :edit if !File.exist?(view_path) }
    end
  end
  
  def create
    respond_to do |format|
      format.html do
        @object = asset_obj.new(params[param_name])
        update_parent_attributes
        before_create
        if @object.save
          after_create
          flash[:notice] = "#{asset_obj.name} created successfully."
          redirect_back_or_default('/')
        else
          flash[:notice] = "Could not create #{asset_obj.name}"
          set_error_sidebar
          render :action => :edit
        end
      end
    end
  end
    
  def update
    respond_to do |format|
      format.html do
        before_update
        if @object.update_attributes(params[param_name])
          after_update
          flash[:notice] = "#{asset_obj.name} updated successfully."
          redirect_back_or_default("/")
        else
          # flash[:notice] = "Information could not be updated"
          set_error_sidebar
          render :action => "edit"
        end
      end
    end
  end
  
  # Edit just renders a form
  def edit; end
  
  # TODO
  def destroy; end
  
  # Ajax-based search
  def live_search
    unless params[:tags].blank?
      @assets = Asset.published_in(publication).published.viewable_by(current_user).order('assets.content_type').find_tagged_with(params[:tags])
    else
      @assets = []
    end
    render :partial => "live_search"    
  end
  
  # Generally implemented in a subclass
  def set_sidebars; end
  
  # Default page size.  Override in subclass as required.
  def page_size
    10
  end
  
protected

  def authorized?
    logged_in? && current_user.is_admin?
  end
  
  def before_retrieve; end
  def after_retrieve; end
  def before_create; end
  def after_create; end
  def before_update; end
  def after_update; end
  
private
    def create_asset
      @object = asset_obj.new
    end

    # Retrieve the asset relating to this request
    def retrieve_this_asset
      retrieve_asset(asset_obj, @object, params[:id])
    end
    
    # Make sure foreign keys are in place at create time
    def update_parent_attributes
      @object.asset.set_created_by(current_user) if asset_obj.respond_to?("polymorph_class")
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
    
    # Retrieve a row from 'target_obj' that has id 'target_id' and store it in instance variable 'instance_variable'
    def retrieve_asset(target_obj, instance_variable, target_id)
      user = asset_obj.respond_to?("polymorph_class") ? current_user : nil
      @object = target_obj.viewable_by(user).find_by_name_or_id(target_id)
      if !@object
        flash[:notice] = "#{target_obj.name} '#{target_id}' not found!"
      else
        @asset = @object.asset if target_obj.respond_to?("polymorph_class")        
      end
      instance_variable_set(instance_variable_singular, @object)
    end  

    # Called from index action, invoke query parameters if any
    def retrieve_assets
      user = asset_obj.respond_to?("polymorph_class") ? current_user : nil
      @objects = asset_obj.viewable_by(user).conditions(marshall_params).with_category(params[:category]) \
                    .pager(unescape(params[:tags]), params[:page], page_size)  
      if @objects.blank?
        flash[:notice] = "#{class_name}: Query '#{format_query_params}' found no items!"
      end
      instance_variable_set(instance_variable_plural, @objects)
    end
    
    # Log the view. Also increment view_count.  We do it this way to avoid changing the
    # updated_at column (which we use to mean update to metadata)
    def log_show
      AssetView.log(@asset, current_user, request.env["HTTP_USER_AGENT"], (request.remote_addr || request.remote_ip))
      Asset.increment_view_count(@asset.id)
    end
    
    def remember_location
      store_location
    end
    
end
