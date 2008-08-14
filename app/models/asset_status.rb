class AssetStatus < ActiveRecord::Base

  def self.status_array
    unless @statti
      @statii = {}
      self.description_hash.each {|k, v| @statii[k.to_sym] = v }
    end
    @statii
  end
  
  def self.description_hash
    unless @descriptions
      @descriptions = {}
      all.each {|s| @descriptions[s.name.downcase] = s.id }
    end
    @descriptions
  end
  
end