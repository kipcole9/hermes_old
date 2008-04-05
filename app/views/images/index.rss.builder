xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title page_title
    xml.link formatted_images_url(:rss)
    xml.pubDate Asset.last_updated(Image)
    xml.description @publication.description
    @images.each do |image|
      xml.item do
        xml.title image.title
        xml.link image_url(image)
        xml.description h(image.description)
        xml.pubDate image.updated_at.to_s(:rfc822)
        xml.guid image_url(image)
        xml.author h(image.created_by.full_name)
      end
    end
  end
end
