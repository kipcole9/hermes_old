atom_feed(:url => formatted_galleries_url(:atom), :root_url => galleries_url, :schema_date => 2008) do |feed|
  feed.title(page_title)
  feed.updated(Asset.last_updated("Gallery"))

  for gallery in @galleries
    feed.entry(gallery) do |entry|
      entry.title(gallery.title)
      entry.content(
        render_to_string(:partial => "images/thumbnail_rss.html.erb", 
          :locals => {:image => gallery.popular_image(current_user), :caption => gallery.title, :gallery => gallery}) + 
				render_description(gallery), :type => 'html')
      entry.author do |author|
        author.name(gallery.created_by.full_name)
        author.email(gallery.created_by.email)
      end
    end
  end
end
