class AddGoogleToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :google_analytics, :string
    add_column :publications, :google_maps, :string
  end

  def self.down
    remove_column :publications, :google_maps
    remove_column :publications, :google_analytics
  end
end
