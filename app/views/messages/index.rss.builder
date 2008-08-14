xml.instruct!
xml.rss "version"       => "2.0",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1", 
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:wfw"     => "http://wellformedweb.org/CommentAPI/",
        "xmlns:dc"      => "http://purl.org/dc/elements/1.1/", 
        "xmlns:atom"    => "http://www.w3.org/2005/Atom" \
do
  xml.channel do
    xml.title "Messages to Administrator"
    xml.link messages_url
    xml.pubDate Message.last.updated_at.rfc822
    xml.description publication.description
    @messages.each do |message|
      xml.item do
        xml.title "Message from '#{message.author_name}'"
        xml.link message_url(message)
        xml.description do
          xml << message.content.strip_tags
        end
        xml.pubDate message.updated_at.rfc822
        xml.author h(message.author_name)
      end
    end
  end
end
