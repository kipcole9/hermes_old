class AddMapTypeToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :map_type, :string, :limit => 10, :default => "Normal"
    execute "update assets set map_type = 'Normal'"
  end

  def self.down
    remove_column :assets, :map_type
  end
end
