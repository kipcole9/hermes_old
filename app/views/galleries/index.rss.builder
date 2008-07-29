xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title page_title
    xml.link formatted_galleries_url(:rss)
    xml.pubDate Asset.last_updated("Gallery").rfc822
    xml.description publication.description
    @galleries.each do |gallery|
      xml.item do
        xml.title gallery.title
        xml.link gallery_url(gallery)
        xml.description do
          xml << h(render_to_string(:partial => "images/thumbnail_rss.html.erb", 
            :locals => {:image => gallery.popular_image(current_user), 
    				:caption => gallery.title, :gallery => gallery}))
          xml << h(render_description(gallery))
        end
        xml.pubDate gallery.updated_at.rfc822
        xml.guid gallery_url(gallery)
        xml.author h(gallery.created_by.full_name)
      end
    end
  end
end
