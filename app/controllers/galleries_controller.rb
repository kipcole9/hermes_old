class GalleriesController < AssetsController
  include Hermes::GeoExtensions
  
  def index_js

  end
  
  def show_js
    
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
  
  def order
    gallery_order = params[:gallery].map{|o| o.to_i}
    @gallery.slides.each do |slide|
      slide.position = slide_position_from_order(slide, gallery_order)
      slide.save unless slide.position == -1
    end
    head :status => 200
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
      @images = @gallery.images.published.published_in(publication).viewable_by(current_user) \
          .order('slides.position').page(params[:page], page_size)
    end
  end
  
  def page_size
    respond_to do |format|
      format.html { return 12  }
      format.js   { return 12  }
      format.any  { return 100 }
    end
  end
  
protected
  
  def slide_position_from_order(slide, gallery_order)
    gallery_order.each_with_index do |image_id, index|
      return index if slide.image_id == image_id
    end
    -1
  end
  
    
end
