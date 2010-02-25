class CategoriesController < ApplicationController

private

  def authorized?
    current_user.is_admin?
  end  
   
end
