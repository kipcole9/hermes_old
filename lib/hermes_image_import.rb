require 'RMagick'
module HermesImageImport
  IMAGE_SUBDIR = "gallery"
  IMAGE_FILE_TYPES = ['.jpg']
  
  # Recursively scan the image library
  # => Create destination directory
  # => Convert the  image into 4 types (large, standard, slide and thumb) and save
  # => Add to the database
  def import_images
    @catalog = Catalog.default
    import_folder(@catalog.source)
  end
  
  def import_folder(folder)
    if File.directory?(folder)
      # puts "Importing images from '#{folder}'."
      Dir.entries(folder).each do |e|
        e_path = folder + e + "/"
        if File.directory?(e_path) 
          if File.exist?(e_path + ".no_image_import") 
            puts "Directory '#{e_path}' marked to not import images"
          else
            if File.directory?(e_path + IMAGE_SUBDIR)
              image_import_one_folder(e_path)
            else
              import_folder(e_path)
            end unless e.match(/^\./) or e == "Recycle Bin"
          end
        end
      end
    else
      puts "'#{folder}' is not a directory or does not exist."
    end
    true
  end
  
  def image_import_one_folder(folder)
    # Check to see if the image has changed before importing
    # puts "Processing images in '#{folder}'."
    destination = "#{@catalog.directory}#{File.basename(folder)}"
    if !File.exist?(destination)
      puts "Making destination folder '#{destination}'."
      FileUtils.mkdir_p(destination)
    end
    
    puts "Importing images from folder '#{folder}'"
    gallery_folder = folder + IMAGE_SUBDIR
    Dir.glob(gallery_folder.with_slash + "**/*.jpg").each do |f|
      if IMAGE_FILE_TYPES.include?(File.extname(f).downcase) && !f.match(/^\./)
        Image.import(f, File.basename(folder))   
      end
    end
  end

  def clear_image_database
    images = Image.find(:all)
    images.each do |i|
      i.asset.destroy
      i.destroy
    end
    puts "Deleted #{images.size} images."
  end
  
end