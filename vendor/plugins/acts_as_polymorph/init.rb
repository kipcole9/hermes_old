require File.dirname(__FILE__) + '/lib/polymorph'
ActiveRecord::Base.send(:include, Hermes::Polymorph)

