class AddIncludeInIndexToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :include_in_index, :boolean, :default => true
    execute 'update assets set include_in_index = 1'
  end

  def self.down
    remove_column :assets, :include_in_index
  end
end
