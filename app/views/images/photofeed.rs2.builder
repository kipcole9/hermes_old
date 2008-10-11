xml.instruct!
xml.rss "version"       => "2.0" do
  xml.channel do
    xml.title page_title
    xml.link images_url(sanitize_params(params))
    xml.pubDate @images.last.updated_at.rfc822
    @images.each do |image|
      xml.item do
        xml.title image.title
        xml.pubDate image.updated_at.rfc822
        xml.description do
          xml << "<![CDATA[<img src=\"" + image_url(image) + "-full.jpg\"" + " />]]>"
        end     
      end
    end
  end
end
