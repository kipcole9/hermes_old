class AddAllowPingbackToAsset < ActiveRecord::Migration
  def self.up
    add_column :assets, :allow_pingbacks, :boolean
    execute 'UPDATE assets SET allow_pingbacks = 1'
  end

  def self.down
    remove_column :assets, :allow_pingbacks
  end
end
