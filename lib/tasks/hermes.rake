namespace :hermes do
  
  desc "Import Image Library"
  task(:import_images => :environment) do
    require "hermes_image_import"
    include HermesImageImport
    User.current_user = User.admin
    import_images
  end
  
  desc "List changed images"
  task(:changed_images => :environment) do
    require "hermes_image_import"
    include HermesImageImport
    User.current_user = User.admin    
    changed_images
  end
  
  desc "Geocode all assets"
  task(:geocode_assets => :environment) do
    assets = Asset.find(:all)
    assets.each do |a|
      a.geocode
    end
  end
  
  desc "Create or Update Galleries from metadata"
  task(:update_galleries => :environment) do
    require 'find'
    catalog = Catalog.default
    Publication.current = Publication.default
    if catalog then
      puts "Updating Galleries from catalog."
      User.current_user = User.admin
      find_pattern = "#{catalog.source}places/**/#{Gallery::METADATA_FILENAME}"
      puts "Looking for gallery metadata file in '#{find_pattern}'"
      Dir.glob(find_pattern) do |f|
        if File.file?(f) then
          puts "Creating or updating gallery from file '#{f}'"
          case retcode = Gallery.create_or_update_from_xml(f)
            when :no_metadata     then puts "No metadata found for #{f}"
            when :bad_metadata    then puts "Metadata file found but malformed for #{f}. Ignoring it."
            when :bad_update      then puts "Could not update Gallery in the database for #{f}"
            else puts "Update returned '#{retcode}'"
          end
        end
      end
    else
      puts "Gallery: The catalog '#{catalog}' was not found to update galleries."
    end
  end
  
  desc "Create gallery metadata templates"
  task(:create_gallery_metadata_templates => :environment) do
    catalog = Catalog.default
    if catalog then
      RAILS_DEFAULT_LOGGER.info "Creating Gallery metadata templates."
      galleries = Gallery.find(:all, :include => :asset)
      galleries.each do |g|
        RAILS_DEFAULT_LOGGER.info "  Creating metadata template for #{g.name}"
        g.create_metadata_template(catalog.directory)
      end
      RAILS_DEFAULT_LOGGER.info "Finished creating gallery metadata templates."
    end
  end
  
  # Gallery rating is the minimum rating for any image in the gallery
  # Of course images that our outside the bounds for any viewer cannot be seen
  desc "Updating content ratings for galleries"
  task(:update_gallery_content_ratings => :environment) do
    rows = Gallery.find(:all, :select => "galleries.id, min(assets.content_rating) as rating",
                        :joins => "join slides on slides.gallery_id = galleries.id join images on images.id = slides.image_id " +
                                  "join assets on assets.content_id = images.id and assets.content_type = 'Image'",
                        :group => "galleries.id")
    rows.each do |r|
      asset = Asset.find_by_content_id_and_content_type(r.id, "Gallery")
      RAILS_DEFAULT_LOGGER.info "Updating gallery '" + asset.name + "' with rating " + r.rating
      asset.content_rating = r.rating
      asset.save!
    end
  end

  # Import the controlled vocabulary file (controlledvocabulary.com)
  # into the Categories and Synonyms tables
  desc "Import controlled vocabulary"
  task(:import_controlled_vocabulary => :environment) do
    require 'hermes_keywords_import'
    include HermesKeywordsImport
    import_keywords
  end

  # Clear out all images
  desc "Delete images from database"
  task(:delete_images => :environment) do
    User.current_user = User.admin
    Publication.current = Publication.default
    Image.destroy_all
  end
  
end
