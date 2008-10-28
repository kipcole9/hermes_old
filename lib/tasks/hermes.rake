namespace :hermes do
  
  desc "Upload Images"
  task(:upload_images => :environment) do
    include Hermes::Image::Import
    User.current_user = User.admin
    upload_images ENV["dir"]
  end
  
  desc "List changed images"
  task(:changed_images => :environment) do
    include Hermes::Image::Import
    User.current_user = User.admin    
    changed_images ENV["dir"]
  end
  
  desc "Geocode all assets"
  task(:geocode_assets => :environment) do
    assets = Asset.find(:all)
    assets.each do |a|
      a.geocode
      a.save!
    end
  end
  
  desc "Create sitemap"
  task(:create_sitemap => :environment) do
    include Hermes::Sitemap
    create_sitemap ENV["dir"]
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
    include Hermes::KeywordsImport
    import_keywords
  end

  # Clear out all images
  desc "Delete images from database"
  task(:delete_images => :environment) do
    User.current_user = User.admin
    Publication.current = Publication.default
    Image.destroy_all
  end
  
  desc "Import image email"
  task(:import_image_email => :environment) do
    Publication.current = Publication.default
    mail_config = YAML::load_file("#{RAILS_ROOT}/config/mailer_credentials.yml")["#{RAILS_ENV}"].symbolize_keys    
    handler = Hermes::Mail.new(:host => mail_config[:mail_host], :user => mail_config[:image_mail_user], :password => mail_config[:image_mail_password])
    puts "About to import image emails."
    handler.get_mail(:delete => true) do |m|
      if (user = User.authorise_and_set(m.from))
        if m.images.empty?
          puts "No images found in the message '#{m.subject}' from #{m.from}"
        else
          options = m.extract_options
          puts "Importing '#{m.subject}' from '#{m.from}'"
          if image = Image.import(m.images.first, options)
            image.save!
            puts "Image #{m.images.first} was imported."
          else
            puts "Import #{m.images.first} failed."
          end
        end
      else
        puts "User #{m.from} is not authorised to send image emails."
      end
    end
    puts "Finished importing image emails."
  end

end
