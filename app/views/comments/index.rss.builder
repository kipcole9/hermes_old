xml.instruct!
xml.rss "version"       => "2.0",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1", 
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:wfw"     => "http://wellformedweb.org/CommentAPI/",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1/", 
        "xmlns:atom"    => "http://www.w3.org/2005/Atom" \
do
  xml.channel do
    xml.title "Recent Comments"
    xml.link root_url
    xml.pubDate @comments.load_page.first.updated_at.rfc822
    xml.description publication.description
    @comments.each do |comment|
      xml.item do
        xml.title "Comment for '#{comment.asset.title}'"
        xml.link "#{polymorphic_url(comment.asset.content)}/#comments"
        xml.description do
          xml << comment.content.strip_tags
        end
        xml.pubDate comment.updated_at.rfc822
        xml.author h(comment.author_name)
      end
    end
  end
end
