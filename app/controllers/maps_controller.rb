class MapsController < AssetsController
  
  def world3
    @map = GMap.new("_largeMap")
  	@map.control_init(:large_map => true,:map_type => :hybrid)
  	@map.set_map_type_init(GMapType::G_HYBRID_MAP)
  	@map.center_zoom_init([0.0,0.0],2)
  	
  	# Mark all assets on the map in a cluster
  	markers = []
  	assets = Asset.find(:all, :conditions => "latitude IS NOT NULL AND longitude IS NOT NULL and latitude <> 0 and longitude <> 0")
  	assets.each do |a|
  	  info_window = render_to_string :partial => "infoWindow", :locals => {:asset => a}
  	  markers << GMarker.new([a.latitude, a.longitude], :info_window => info_window, :title => a.title, :description => a.description)
	  end
	  @map.overlay_init(Clusterer.new(markers))
  end
  
  def world2
    @map = GMap.new("_largeMap")
  	@map.control_init(:large_map => true,:map_type => :hybrid)
  	@map.set_map_type_init(GMapType::G_HYBRID_MAP)
  	@map.center_zoom_init([18,102],8)
    @map.overlay_init(GGeoXml.new("http://refuge.noexpectations.com.au:3000/kml/luang-prabang-to-vientiane.kml"))
  end
  
  def world
    @map = GMap.new("_largeMap")
  	@map.control_init(:large_map => true,:map_type => :hybrid)
  	@map.set_map_type_init(GMapType::G_HYBRID_MAP)
  	@map.center_zoom_init([0.0,0.0],2)
  	
  	# Mark all galleries on a map
  	markers = []
  	galleries = Gallery.viewable_by(current_user) \
  	  .find(:all, :conditions => "latitude IS NOT NULL AND longitude IS NOT NULL and latitude <> 0 and longitude <> 0")
  	if galleries.length > 0
    	galleries.each do |g|
    	  info_window = render_to_string :partial => "infoWindow", 
    	    :locals => {:image_name => g.popular_image(current_user).name, :asset => g}
    	  markers << GMarker.new([g.latitude, g.longitude], :info_window => info_window, 
    	    :title => g.title, :description => g.description)
  	  end
      @map.overlay_init(markers[0])
      markers[1..-1].each do |m|
        @map.record_init @map.add_overlay(m)
      end
    end
  end
	   
	  
  	
end