class AddPublicationToAssetView < ActiveRecord::Migration
  def self.up
    add_column :asset_views, :publication_id, :integer
  end

  def self.down
    remove_column :asset_views, :publication_id
  end
end
