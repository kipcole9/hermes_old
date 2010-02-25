class AddReferrerToAssetViews < ActiveRecord::Migration
  def self.up
    add_column :asset_views, :referrer, :string
  end

  def self.down
    remove_column :asset_views, :referrer
  end
end
