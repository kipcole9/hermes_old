xml.instruct!
xml.kml "xmlns:atom" => "http://www.w3.org/2005/Atom", :xmlns => "http://www.opengis.net/kml/2.2" do
  xml.Document :id => @gallery.name do
    add_document_basic_data(xml, @gallery)
    add_pushpin_style(xml)
    xml.Folder do
      xml.name "Gallery Images"
      xml.open "1"
      @gallery.images.each do |image|
        add_image_placemark(xml, image, :extended_data => true)
      end
    end
  end
end

