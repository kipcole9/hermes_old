class CreatePingbackTable < ActiveRecord::Migration
  def self.up
    create_table :pingbacks do |t|
      t.string        :target_uri
      t.string        :source_uri
      t.timestamps
    end
    add_index :pingbacks, [:target_uri, :source_uri], :unique => true
  end

  def self.down
    drop_table :pingbacks
  end
end
