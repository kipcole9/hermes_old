class Map < ActiveRecord::Base
  include HermesModelExtensions
  acts_as_polymorph
  acts_as_secure
  

end