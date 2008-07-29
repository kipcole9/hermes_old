class AddAdminEmailToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :admin_email, :string
  end

  def self.down
    remove_column :publications, :admin_email
  end
end
