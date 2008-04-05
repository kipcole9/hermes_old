class AssetView < ActiveRecord::Base
  def self.log(asset, user, browser_type, remote_ip)
    self.create!(:asset_id => asset.id, :user_id => (user == :false ? 0 : user.id), :browser_type => browser_type,
                :ip_address => remote_ip)
  end
end