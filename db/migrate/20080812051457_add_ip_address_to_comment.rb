class AddIpAddressToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :ip_address, :string, :limit => 20
  end

  def self.down
    remove_column :comments, :ip_address
  end
end
