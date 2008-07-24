class CommentsController < ApplicationController
  include HermesControllerExtensions
  before_filter :login_required, :except => [ :create ]
  before_filter :comments_open?, :only => [:create, :edit]  
  
  def create
    comment = Comment.new(params[:comment])
    comment.status = Asset::STATUS[:draft] if comment.asset.moderate_comments?
    comment.created_by = current_user if logged_in?
    flash[:notice] = flash_errors("Could not create comment", comment) unless comment.save
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
      redirect_back_or_default('/')
    end
  end
  
  def edit
    
  end
  
  def spam
    
  end
  
  def nospam
    
  end

private

  def comments_open?
    return false unless asset = Asset.find(params[:asset_id])
    return asset.comments_open?
  end
  
end