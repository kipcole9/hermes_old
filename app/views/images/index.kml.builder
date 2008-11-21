xml.instruct!
xml.kml :xmlns => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.Document do
    add_document_basic_data(xml, @images, :name => h("#{publication.title} Selected Images"),
                                          :description => page_title,
                                          :author => @images[0] ? @images[0].created_by.full_name : User.admin.full_name,
                                          :url => images_url(sanitize_params(params)))
    add_pushpin_style(xml)
    
    xml.Folder do
      xml.name "Selected Images"
      xml.open "1"
      @images.each do |image|
        add_image_placemark(xml, image, :extended_data => true)
      end
    end
  end
end



