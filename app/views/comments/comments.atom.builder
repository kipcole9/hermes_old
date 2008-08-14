atom_feed(:url => formatted_comments_article_url(@object), :root_url => root_url, :schema_date => 2008) do |feed|
  feed.title("Comments for #{@object.class.name} '#{@object.title}'")
  feed.updated(@object.updated_at)
  for comment in @comments
    feed.entry(comment, :url => "#{polymorphic_url(@object)}/#comments") do |entry|
      entry.title("Comment for '#{@object.title}'")
      entry.content(comment.content.strip_tags)
      entry.author do |author|
        author.name(comment.author_name)
      end
    end
  end
end
