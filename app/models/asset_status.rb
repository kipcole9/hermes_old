class AssetStatus < ActiveRecord::Base

  def self.status_array
    statii = {}
    status = find(:all)
    status.each {|s| statii[s.name.downcase.to_sym] = s.id }
    statii
  end
  
end