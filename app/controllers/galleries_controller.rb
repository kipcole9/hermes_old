class GalleriesController < AssetsController
  include Hermes::GeoExtensions
  
  def index_js

  end
  
  def show_kml
    if @gallery.mappable?
      render :action => "show"
    else
      page_not_found("Gallery '#{@gallery.title}' is not geocoded so kml cannot be rendered")
    end
  end
  
  def show_rss
    render :action => "show"
  end
  
  def show_rs2
    render :action => "photofeed"
  end
  
  def show_js
    
  end
  
  def index_kml
    render :action => "index"
  end
  
  def recent
    respond_to do |format|
      format.html 
      format.js {render :partial => "sidebars/galleries_recent.html.erb", :locals => {:ajax => true} }
    end
  end

  def popular
    respond_to do |format|
      format.html
      format.js {render :partial => "sidebars/galleries_popular.html.erb", :locals => {:ajax => true} }
    end
  end
  
  def after_retrieve_object
    if params[:action] == "show"
      @images = @gallery.images.published.published_in(publication).viewable_by(current_user).page(params[:page], page_size)
    end
  end
  
  def page_size
    12
  end
    
end
