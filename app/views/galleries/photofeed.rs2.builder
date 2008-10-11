xml.instruct!
xml.rss "version"       => "2.0" do
  xml.channel do
    @gallery.images.each do |image|
      xml.item do
        xml.title image.title
        xml.description do
          xml << "<![CDATA[<img src=\"" + image_url(image) + "-full/serve\"" + " />]]>"
        end     
      end
    end
  end
end
