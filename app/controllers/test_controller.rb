class TestController < ApplicationController
  
  def test
    send_file Image.find(:first).full_path_name, :disposition => 'inline', :x_sendfile => true
  end
  
  
end