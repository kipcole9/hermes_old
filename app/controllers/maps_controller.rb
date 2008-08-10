class MapsController < AssetsController
  
  def world
    @map = GMap.new("_largeMap")
  	@map.control_init(:large_map => true,:map_type => :hybrid)
  	@map.set_map_type_init(GMapType::G_HYBRID_MAP)
  	@map.center_zoom_init([0.0,0.0],2)
  	
  	# Mark all galleries on a map
  	markers = []
  	galleries = Gallery.viewable_by(current_user).published_in(publication).published \
  	  .find(:all, :conditions => "latitude IS NOT NULL AND longitude IS NOT NULL and latitude <> 0 and longitude <> 0")
  	if galleries.length > 0
    	galleries.each do |g|
    	  info_window = render_to_string :partial => "infoWindow", :locals => {:image_name => g.popular_image(current_user).name, :asset => g}
    	  markers << GMarker.new([g.latitude, g.longitude], :info_window => info_window, :title => g.title, :description => g.title)
  	  end
      @map.overlay_init(markers[0])
      markers[1..-1].each do |m|
        @map.record_init @map.add_overlay(m)
      end
    end
  end
  
  def index
    flash[:notice] = nil
    redirect_to :action => :world
  end
	   	
end