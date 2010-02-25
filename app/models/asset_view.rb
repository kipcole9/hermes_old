class AssetView < ActiveRecord::Base
  def self.log(publication, asset, user, browser_type, remote_ip, referrer, format)
    self.create!(:publication_id => publication, 
                :asset_id   => asset.attributes["id"],
                :user_id    => (user == :false ? 0 : user.id),
                :user_agent => browser_type,
                :ip_address => remote_ip,
                :referrer   => referrer,
                :format     => format)
  end
end