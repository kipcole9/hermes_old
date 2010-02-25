class AddFormatToAssetView < ActiveRecord::Migration
  def self.up
    add_column :asset_views, :format, :string, :limit => 5
  end

  def self.down
    remove_column :asset_views, :format
  end
end
