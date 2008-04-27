class CommentsController < ApplicationController
  include HermesControllerExtensions
  before_filter :login_required, :except => [ :create ]  
  
  def create
    comment = Comment.new(params[:comment])
    comment.created_by = current_user if logged_in?
    if !comment.save
      flash[:notice] = flash_errors("Could not create comment", comment)
    end
    redirect_back_or_default("/")
  end
  
  def destroy
    if Comment.delete(params[:id])
      respond_to do |format|
        format.js do
          render :update do |page| 
              page["comment_#{params[:id].to_s}"].hide
          end
        end
      end
    else
      flash[:notice] = "Could not delete the comment"
    end
  end
  
  def edit
    
  end
  
  def spam
    
  end
  
  def nospam
    
  end
  
end