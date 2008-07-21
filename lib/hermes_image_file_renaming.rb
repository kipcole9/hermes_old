module HermesImageFileRenaming
  
  # For each directory, check to see if it has a raw and edited folder
  # If so, go through and rename the raw files to be the name of the main
  # folder followed by a 5 digit number.  Store the mappings of old to new.
  # Then visit the other folders (prints, email, jpeg) and rename them
  # using the mapping from the Raw folder to that we can still correlate
  # which raw file an edited one came from.
  require 'find'
  
  def rename_images(folder)
    if folder.is_a?(Array)
      folder.each {|f| rename_images_folder(f)}
    else
      if File.directory?(folder)
        Dir.entries(folder).each do |e|
          e_path = folder + "/" + e
          if File.directory?(e_path) 
            if File.exist?(e_path + "/.no_image_import") 
              puts "Directory '#{e_path}' marked to not import images"
            else
              if File.directory?(e_path + "/raw")
                rename_images_folder(e_path)
              else 
                rename_images(e_path)
              end unless e.match(/^\./) or e == "Recycle Bin"
            end
          end
        end
      else
        puts "'#{folder}' is not a directory or does not exist."
      end
      true
    end
  end
  
  
  def rename_images_folder(folder)
    if !File.directory?(folder)
      puts "'#{folder}' is not a directory or does not exist."
      return false
    end
    
    puts "Renaming for folder '#{folder}"  
    file_types = [".tif", ".xmp", ".psd", ".crw", ".cr2", ".jpeg", ".jpg", ".dng", ".png"]
    raw_file_types = [".tif", ".crw", ".cr2", ".jpg", ".dng", ".tif"]
    file_name_root = File.basename(folder)
    file_number = 0
    rename_count = 0
    rename_map = {}
    Dir.entries(folder).select {|d| d.match(/^raw/i) }.each do |d|
      puts "Processing raw folder #{folder}/#{d}"
      files = Dir.entries("#{folder}/#{d}").map {|f| raw_file_types.include?(File.extname(f).downcase) ? File.basename(f,'.*') : nil }.compact.uniq.sort
      files.each do |f|
        rename_map[f] = "#{file_name_root}-#{'%05d' % file_number}"
        file_number += 1
      end
    end
    
    if rename_map.length == 0 
      puts "No files found to rename in '#{folder}'."
      return false
    end
    
    # Now process the sub-folders and do the renaming
    # For now because we're being brutal and lazy and conservative we're only renaming 
    # certain object types
    Find.find(folder) do |f|
       if File.file?(f) && file_types.include?(File.extname(f).downcase)
         extension = File.extname(f)
         basename = File.basename(f, '.*')
         root_basename = rename_map.select {|k, v| File.basename(f, '.*').match(Regexp.new("^#{k}", true)) ? true : false }
         root_basename = root_basename.length > 0 ? root_basename.first.first : nil
         path = File.dirname(f)
         if rename_map[root_basename]
           new_name = basename.sub(root_basename, rename_map[root_basename]).gsub(/ +/,'-')
           # puts "rename #{f} => #{path}/#{new_name}#{extension}"
           begin
             File.rename(f, "#{path}/#{new_name}#{extension}")
             rename_count += 1
           rescue SystemCallError
             puts "Could not rename #{f} => #{path}/#{new_name}#{extension}"
           end
         end
       end
    end
    puts "Renamed #{rename_count} files."
    true
  end
end
        