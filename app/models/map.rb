class Map < ActiveRecord::Base
  acts_as_polymorph
  acts_as_polymorph_taggable
  acts_as_secure
  acts_as_hermes
  
  def to_param
    self.name
  end  
  

end