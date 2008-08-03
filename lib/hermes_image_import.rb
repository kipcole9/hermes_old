require 'RMagick'
include HermesUpload

module HermesImageImport
  IMAGE_SUBDIR = "gallery"
  IMAGE_FILE_TYPES = ['.jpg']
  
  # Recursively scan the image library
  # => Create destination directory
  # => Convert the  image into 4 types (large, standard, slide and thumb) and save
  # => Add to the database
  def import_images(dir = nil)
    @catalog = Catalog.default
    proc = lambda {|file, folder| upload_image(file, folder) }
    directory = dir || @catalog.source
    process_folder(directory, proc)   
  end
  
  def changed_images
    @catalog = Catalog.default
    proc = lambda { |file, folder| 
      image_exists, updated_at = update_time(file)
      puts "#{file} has changed since last import." if image_exists && File.mtime(file) > updated_at
      puts "#{file} is new since last import." unless image_exists
    }
    process_folder(@catalog.source, proc)
  end   
  
  def process_folder(folder, proc)
    if File.directory?(folder)
      Dir.entries(folder).each do |e|
        e_path = folder.with_slash + e     
        if File.directory?(e_path)
          if File.exist?(e_path + ".no_image_import") 
            puts "Directory '#{e_path}' marked to not import images"
          else
            if File.directory?(e_path.with_slash + IMAGE_SUBDIR)
              process_one_folder(e_path) do |file, folder_name|
                proc.call file, folder_name
              end
            else
              process_folder(e_path, proc)
            end unless e.match(/^\./) or e == "Recycle Bin"
          end
        end
      end
      
      # And now check if we have an image directory
      if File.directory?(folder.with_slash + IMAGE_SUBDIR)
        process_one_folder(folder) do |file, folder_name|
          proc.call file, folder_name
        end
      end      
    else
      puts "'#{folder}' is not a directory or does not exist."
    end    
    true
  end
  
  def process_one_folder(folder)
    # Check to see if the image has changed before importing
    # puts "Processing images in '#{folder}'."
    destination = "#{@catalog.directory}#{File.basename(folder)}"
    if !File.exist?(destination)
      puts "Making destination folder '#{destination}'."
      FileUtils.mkdir_p(destination)
    end
    gallery_folder = folder.with_slash + IMAGE_SUBDIR + "/**/*.jpg"
    Dir.glob(gallery_folder).each do |f|
      if IMAGE_FILE_TYPES.include?(File.extname(f).downcase) && !f.match(/^\./)
        yield f, File.basename(folder)
      end
    end
  end

  def clear_image_database
    image_count = Image.count
    Image.destroy_all
    puts "Deleted #{image_count} images."
  end
  
end