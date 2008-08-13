class AddAllowPingbackToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :allow_pingback, :boolean
    execute 'UPDATE assets SET allow_pingback = 1'
  end

  def self.down
    remove_column :assets, :allow_pingback
  end
end
