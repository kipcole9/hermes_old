class AddZoomLevelToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :map_zoom_level, :integer, :limit => 2, :default => 4
    rename_column :assets, :google_geocoded, :geocode_method
    execute 'update assets set map_zoom_level = 4'
  end

  def self.down
    remove_column :assets, :map_zoom_level
  end
end
