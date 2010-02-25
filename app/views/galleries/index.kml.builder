xml.instruct!
xml.kml :xmlns => "http://www.opengis.net/kml/2.2", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.Document :id => "#{publication.name}-galleries" do
    add_document_basic_data(xml, @images, :name => h("#{publication.title} Image Galleries"),
                                          :description => page_title,
                                          :author => publication.created_by.full_name,
                                          :url => galleries_url(sanitize_params(params)))
    @galleries.each do |gallery|
      xml.NetworkLink :id => gallery.name do
        xml.name gallery.title
        xml.description render_description(gallery)
        xml.flyToView "1"
        xml.Link do
          xml.href formatted_gallery_url(gallery, :kml)
        end
      end
    end
  end
end
