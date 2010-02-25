atom_feed(:url => formatted_images_url(:atom), :root_url => images_url, :schema_date => 2008) do |feed|
  feed.title(page_title)
  feed.updated(Asset.last_updated(Image))

  for image in @images
    feed.entry(image) do |entry|
      entry.title(image.title)
      entry.content(
        render_to_string(:partial => "images/thumbnail_rss.html.erb", :locals => {:image => image}) + 
			  h(render_description(image)), :type => 'html')
      entry.author do |author|
        author.name(image.created_by.full_name)
        author.email(image.created_by.email)
      end
    end
  end
end
