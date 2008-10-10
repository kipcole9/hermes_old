xml.instruct!
xml.kml :xmlns => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.Document do
    xml.name h("No Expectations Selected Images")
    xml.description h(page_title)
    xml.atom :author do
      xml.atom :name, "Kip Cole"
    end
    xml.atom :link, href="http://www.noexpectations.com.au"
    xml.Style :id => "style_image_pushpin" do
      xml.IconStyle do
        xml.scale "1.1"
        xml.Icon do
          xml.href "http://www.noexpectations.com.au/images/icons/photo.png"
        end
      end
    end
    
    xml.folder do
      xml.name "Selected Images"
      xml.open "1"
      @images.each do |image|
        if image && image.latitude && image.longitude
          xml.Placemark do
            xml.name image.title
            gps_note = image.google_geocoded ? "<p><i>Geocoded by Google - location accuracy is to the #{Google_geocode_accuracy[image.geocode_accuracy]} level only.</i></p>" : \
                                               "<p><i>Geocoded from a GPS tracklog - accuracy usually within 3m.</i></p>"
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
