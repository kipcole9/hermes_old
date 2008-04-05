xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1" do
  xml.channel do
    xml.title page_title
    xml.link formatted_articles_url(:rss)
    xml.pubDate Asset.last_updated("Article")
    xml.description @publication.description
    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.link formatted_article_url(article, :rss)
        xml.description h(article.description)
        xml.pubDate article.updated_at.to_s(:rfc822)
        xml.guid article_url(article, :only_path => false)
        xml.author h(article.created_by.full_name)
      end
    end
  end
end
