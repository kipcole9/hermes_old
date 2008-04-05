class AssetStatus < ActiveRecord::Base

  def self.status_array
    statii = {}
    status = find(:all)
    status.each {|s| statii[s.name.downcase] = s.id }
    statii
  end
  
end