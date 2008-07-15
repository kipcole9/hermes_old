class Tester < ActiveRecord::Base
  
  attr_accessible :access
  attr_protected :denied
  
end