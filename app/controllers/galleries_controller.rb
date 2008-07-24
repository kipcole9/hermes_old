class GalleriesController < AssetsController
  
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
  
  def refresh_all
    Galleries.all.each {|g| g.refresh }
    head :200
  end
    
  def page_size
    12
  end
    
end
