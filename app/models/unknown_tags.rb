require 'mini_exiftool'
require 'hermes_image_metadata_import'
include HermesImageMetadataImport

class UnknownTags < ActiveRecord::Base
  def self.add(tag)
    ut = find_by_name(tag) || new(:name => tag)
    ut.tag_count += 1
    ut.save!
  end
  
  def self.update_tags
    unknown = find(:all, :order => "position")
    updates = 0
    unknown.each do |u|
      if u.add_to && Tag.add_child(u.add_to, u.name)
        puts "Added tag '#{u.name}' to category '#{u.add_to}'"
        u.destroy
        updates += 1
      elsif u.synonym_of && Tag.add_synonym(u.synonym_of, u.name)
        puts "Added '#{u.name}' as synonym of '#{u.synonym_of}'"
        u.destroy
        updates += 1
      end
    end
    Tag.build_nested_set if updates > 0
  end
  
  def self.images_with
    unknowns = find(:all).map(&:name)
    images = Image.find(:all)
    images.each do |i|
      tags = TagList.from(MiniExiftool.new(i.full_path_name).subject)
      tags.each do |t|
        if unknowns.include?(t)
          update_unknown(t, i.name)
        end
      end
    end
    true
  end
  
  def self.update_unknown(name, image_name)
    if u = UnknownTags.find(:first, :conditions => ["name = ?", name])
      u.found_in = u.found_in ? (u.found_in + "," + image_name) : image_name
      u.save!
    else
      logger.error("UnknownTags: update_unknown: Tag '#{name}' was not found.")
    end
  end
      
      
    
end