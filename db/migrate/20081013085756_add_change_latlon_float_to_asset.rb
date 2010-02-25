class AddChangeLatlonFloatToAsset < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `assets` CHANGE `altitude` `altitude` double DEFAULT NULL;"
    execute  "ALTER TABLE `assets` CHANGE `latitude` `latitude` double DEFAULT NULL;"
    execute  "ALTER TABLE `assets` CHANGE `longitude` `longitude` double DEFAULT NULL;"
  end

  def self.down
  end
end
