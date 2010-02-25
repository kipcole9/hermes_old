require File.dirname(__FILE__) + '/lib/secure'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Secure)

