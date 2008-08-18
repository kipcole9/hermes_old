class AddIgnoreUrlErrorsToBookmark < ActiveRecord::Migration
  def self.up
    add_column :bookmarks, :ignore_url_errors, :boolean, :default => false
    add_column :bookmarks, :http_response_code, :string, :limit => 3
  end

  def self.down
    remove_column :bookmarks, :ignore_url_errors
    remove_column :bookmarks, :http_response_code
  end
end
