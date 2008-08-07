namespace :hermes do
  
  desc "Upload Images"
  task(:upload_images => :environment) do
    require "hermes_image_import"
    include HermesImageImport
    User.current_user = User.admin
    import_images ENV["dir"]
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
      a.save!
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
