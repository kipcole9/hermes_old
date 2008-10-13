class GalleriesController < AssetsController
  
  def show_kml
    render :action => "show"
  end
  
  def show_rss
    render :action => "show"
  end
  
  def show_rs2
    render :action => "photofeed"
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

  def page_size
    12
  end
    
end
