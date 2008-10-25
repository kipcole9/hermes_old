class Map < ActiveRecord::Base
  acts_as_polymorph
  acts_as_polymorph_taggable
  acts_as_secure
  

end