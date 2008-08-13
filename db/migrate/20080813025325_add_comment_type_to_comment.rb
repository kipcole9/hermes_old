class AddCommentTypeToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :comment_type, :string, :limit => 10
    execute "UPDATE comments SET comment_type = 'comment'"
  end

  def self.down
    remove_column :comments, :comment_type
  end
end
