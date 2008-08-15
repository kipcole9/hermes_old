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
    xml.link formatted_images_url(:rss)
    xml.pubDate Asset.last_updated(Image)
    xml.description publication.description
    @images.each do |image|
      xml.item do
        xml.title image.title
        xml.link image_url(image)
        xml.description h(image.description)
        xml.description do
          xml << h(render_to_string(:partial => "images/thumbnail_rss.html.erb", :locals => {:image => image}))
          xml << h(render_description(image))
        end
        if image.comments.published.count > 0
          xml.comments(image_url(article) + "/#comments") 
          xml.wfw :commentRss, formatted_comments_image_url(article, :rss)
        end
        xml.pubDate image.updated_at.to_s(:rfc822)
        xml.guid image_url(image)
        xml.author h(image.created_by.full_name)
      end
    end
  end
end
