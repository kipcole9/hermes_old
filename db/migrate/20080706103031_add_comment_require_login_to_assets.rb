class AddCommentRequireLoginToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :comments_require_login, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :assets, :comments_require_login
  end
end
