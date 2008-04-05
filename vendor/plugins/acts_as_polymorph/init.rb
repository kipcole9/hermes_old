require File.dirname(__FILE__) + '/lib/polymorph'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Polymorph)

