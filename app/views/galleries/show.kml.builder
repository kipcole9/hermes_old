xml.instruct!
xml.kml "version" => "1.0", :xmlns => "http://earth.google.com/kml/2.2" do
  xml.Document do
    xml.name h(@gallery.title)
    xml.description h(@gallery.description)
    xml.Style :id => "style_image_pushpin" do
      xml.IconStyle do
        xml.scale "1.1"
        xml.Icon do
          xml.href "http://www.noexpectations.com.au/images/icons/photo.png"
        end
      end
    end
    
    xml.folder do
      xml.name "Gallery Images"
      xml.open "1"
      @gallery.images.each do |image|
        if image.latitude && image.longitude
          xml.Placemark do
            xml.name image.title
            gps_note = image.google_geocoded ? "<p><i>Geocoded by Google</i></p>" : "<p><i>Located with GPS.</i></p>"
            xml.description "<p><img src=\"#{image_url(image)}-display/serve\" ></p>" + render_description(image) + gps_note
            xml.styleUrl "#style_image_pushpin"
            xml.Point do
              xml.coordinates "#{image.longitude},#{image.latitude},0"
            end
          end
        end
      end
    end
  end
end
