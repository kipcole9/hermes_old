require 'rmagick'
module HermesImageImport
  
  # Recursively scan the image library
  # => Create destination directory
  # => Convert the  image into 4 types (large, standard, slide and thumb) and save
  # => Add to the database
  def import
    @catalog = Catalog.default_catalog
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
            if File.directory?(e_path + "gallery/jpeg")
              image_import_one_folder(e_path, options)
            else 
              image_import(e_path, options)
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
    puts "Importing images from '#{folder}'."
    destination = "#{@catalog.directory}#{File.basename(folder)}"
    @file_types ||= ['.jpg']
    if !File.exist?(destination)
      puts "Making destination folder '#{destination}'."
      FileUtils.mkdir_p(destination)
    end
    
    Dir.entries(folder + "gallery/jpeg").each do |f|
      if @file_types.include?(File.extname(f).downcase) && !f.match(/^\./)
        Image.import(full_file)   
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