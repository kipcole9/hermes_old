xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title page_title
    xml.link formatted_galleries_url(:rss)
    xml.pubDate Asset.last_updated("Gallery")
    xml.description @publication.description
    @galleries.each do |gallery|
      xml.item do
        xml.title gallery.title
        xml.link formatted_gallery_url(gallery, :rss)
        xml.description h(gallery.description)
        xml.pubDate gallery.updated_at.to_s(:rfc822)
        xml.guid gallery_url(gallery, :only_path => false)
        xml.author h(gallery.created_by.full_name)
      end
    end
  end
end
