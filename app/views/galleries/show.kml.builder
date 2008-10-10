xml.instruct!
xml.kml :xmlns => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.Document do
    add_document_basic_data(xml, @gallery)
    add_pushpin_style(xml)
    xml.folder do
      xml.name "Gallery Images"
      xml.open "1"
      @gallery.images.each do |image|
        add_image_placemark(xml, image, :extended_data => true)
      end
    end
  end
end

