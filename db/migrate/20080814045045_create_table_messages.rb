class CreateTableMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string        :created_by_name, :limit => 50
      t.string        :created_by_email, :limit => 50
      t.string        :website
      t.text          :content
      t.integer       :created_by
      t.string        :ip_address, :limit => 20
      t.string        :browser
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
