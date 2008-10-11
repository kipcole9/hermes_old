xml.instruct!
xml.rss "version"       => "2.0",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1", 
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:wfw"     => "http://wellformedweb.org/CommentAPI/",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1/", 
        "xmlns:georss"  => "http://www.georss.org/georss",
        "xmlns:media"   => "http://search.yahoo.com/mrss/",
        "xmlns:atom"    => "http://www.w3.org/2005/Atom" \
do
  xml.channel do
    xml.title page_title
    xml.link images_url
    xml.atom :link, :href => formatted_images_url(:rss), :rel => "self", :type => "application/rss+xml"
    xml.pubDate Asset.last_updated(Image).rfc822
    xml.description publication.description
    @images.each do |image|
      xml.item do
        xml.title image.title
        xml.link image_url(image)
        xml.description do
          xml << h(render_to_string(:partial => "images/thumbnail_rss.html.erb", :locals => {:image => image}))
          xml << h(render_description(image))
        end
        if image.comments.published.count > 0
          xml.comments(image_url(image) + "/#comments") 
          xml.wfw :commentRss, formatted_comments_image_url(image, :rss)
        end
        xml.pubDate image.updated_at.rfc822
        xml.guid image_url(image)
        xml.dc :creator, h(image.created_by.full_name)
        xml.georss :point, "#{image.latitude} #{image.longitude}" if image.mappable?
        xml.media :content, :url => "#{serve_image_link(image, :type => :display)}", :medium => "image", :type => "image/jpeg"
        xml.media :title, image.title
        xml.media :credit, :role => "photographer" do
          xml << image.created_by.full_name
        end if image.created_by.full_name
        xml.media :copyright, image.copyright_notice if image.copyright_notice          
      end
    end
  end
end
