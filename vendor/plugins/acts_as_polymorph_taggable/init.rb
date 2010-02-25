require File.dirname(__FILE__) + '/lib/acts_as_polymorph_taggable'
ActiveRecord::Base.send(:include, Hermes::Polymorph::Taggable)
