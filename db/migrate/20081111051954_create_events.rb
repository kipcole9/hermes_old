class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table "events", :force => true do |t|
      t.string            :frequency
    end
    
    create_table "event_instances" do |t|
      t.datetime          :starts_at
      t.datetime          :ends_at
    end
  end

  def self.down
    delete_table "events"
    delete_table "event_instances"
  end
end
