xml.instruct!
xml.kml :xmlns => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.Document do  
    add_document_basic_data(xml, @image, :no_description => true)
    add_asset_extended_data(xml, @image)
    add_pushpin_style(xml)
    add_image_placemark(xml, @image)
  end
end
