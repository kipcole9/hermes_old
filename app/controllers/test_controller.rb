class TestController < ApplicationController
  
  attr_accessible :access
  attr_protected :denied
  
  def test
    send_file Image.find(:first).full_path_name, :disposition => 'inline', :x_sendfile => true
  end
  
  
end