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
    xml.link root_url
    xml.atom :link, :href => formatted_articles_url(:rss), :rel => "self", :type => "application/rss+xml"
    xml.pubDate Asset.last_updated("Article").rfc822
    xml.description publication.description
    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link article_url(article)
        xml.description do
          xml << h(render_description(article))
        end
        if article.comments.published.count > 0
          xml.comments(article_url(article) + "/#comments") 
          xml.wfw :commentRss, formatted_comments_article_url(article, :rss)
        end
        xml.pubDate article.updated_at.rfc822
        xml.guid article_url(article)
        xml.dc :creator, h(article.created_by.full_name)
      end
    end
  end
end
