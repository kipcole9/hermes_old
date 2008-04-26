atom_feed(:url => formatted_articles_url(:atom), :root_url => articles_url, :schema_date => 2008) do |feed|
  feed.title(page_title)
  feed.updated(Asset.last_updated(Article))

  for article in @articles
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(render_description(article), :type => 'html')

      entry.author do |author|
        author.name(article.created_by.full_name)
        author.email(article.created_by.email)
      end
    end
  end
end
