class AddCopyrightToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :copyright_notice, :string
    execute "UPDATE assets JOIN images ON assets.content_id = images.id AND assets.content_type = 'Image' SET assets.copyright_notice = images.copyright_notice"
    remove_column :images, :copyright_notice
  end

  def self.down
    add_column :images, :copyright_notice, :string
    execute "UPDATE assets JOIN images ON assets.content_id = images.id AND assets.content_type = 'Image' SET images.copyright_notice = assets.copyright_notice"    
    remove_column :assets, :copyright_notice

  end
end
