class Event < ActiveRecord::Base
  acts_as_polymorph
  acts_as_secure
  acts_as_hermes
  has_many      :event_instances
  
  
end
