require File.dirname(__FILE__) + '/lib/acts_as_hermes.rb'
ActiveRecord::Base.send(:include, Hermes::ModelExtensions)