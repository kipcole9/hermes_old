xml.instruct!
xml.rss "version"       => "2.0",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1", 
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:wfw"     => "http://wellformedweb.org/CommentAPI/",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1/", 
        "xmlns:atom"    => "http://www.w3.org/2005/Atom" \
do
  xml.channel do
    xml.title page_title
    xml.link galleries_url
    xml.atom :link, :href => formatted_galleries_url(:rss), :rel => "self", :type => "application/rss+xml"
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
        if gallery.comments.published.count > 0
          xml.comments(gallery_url(gallery) + "/#comments") 
          xml.wfw :commentRss, formatted_comments_gallery_url(gallery, :rss)
        end
        xml.pubDate gallery.updated_at.rfc822
        xml.guid gallery_url(gallery)
        xml.dc :creator, h(gallery.created_by.full_name)
      end
    end
  end
end
