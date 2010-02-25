class AddDefensioToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :defensio_api_key, :string, :limit => 100
  end

  def self.down
    remove_column :publications, :defensio_api_key
  end
end
