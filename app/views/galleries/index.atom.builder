atom_feed(:url => formatted_galleries_url(:atom), :root_url => galleries_url, :schema_date => 2008) do |feed|
  feed.title(page_title)
  feed.updated(Asset.last_updated("Gallery"))

  for gallery in @galleries
    feed.entry(gallery) do |entry|
      entry.title(gallery.title)
      entry.content(gallery.description, :type => 'text')

      entry.author do |author|
        author.name(gallery.created_by.full_name)
        author.email(gallery.created_by.email)
      end
    end
  end
end
