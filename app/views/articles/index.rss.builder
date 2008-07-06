xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title page_title
    xml.link formatted_articles_url(:rss)
    xml.pubDate Asset.last_updated("Article").rfc822
    xml.description publication.description
    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link formatted_article_url(article, :rss)
        xml.description do
          xml << h(render_description(article))
        end
        xml.pubDate article.updated_at.rfc822
        xml.guid article_url(article, :only_path => false)
        xml.author h(article.created_by.full_name)
      end
    end
  end
end
