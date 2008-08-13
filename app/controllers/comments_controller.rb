class CommentsController < ApplicationController
  include HermesControllerExtensions
  before_filter :login_required, :except => [ :create ]
  before_filter :comments_open?, :only => [:create, :edit]
  before_filter :retrieve_comment, :only => [:ham, :spam]
  
  def index
    @comments = Comment.all
  end
  
  def create
    comment = Comment.new(params[:comment])
    comment.created_by = current_user if logged_in?
    flash[:notice] = "Comment not saved: #{comment.errors.full_messages.join(', ')}." unless comment.save
    flash[:notice] = "Your comment has been saved for moderation" if comment.status == Asset::STATUS[:draft]
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
    defensio = Defensio.new(:no_validate_key => true)
    if defensio.report_false_positive(@comment)
      @comment.spam = true
      @comment.status = Asset::STATUS[:draft]
      @comment.save!
      respond_to do |format|
        format.js do
          render :update do |page| 
              page["ham_#{params[:id].to_s}"].replace_html "Marked as spam"
          end
        end
      end
    end
  end
  
  def ham
    defensio = Defensio.new(:no_validate_key => true)
    if defensio.report_false_negative(@comment)
      @comment.spam = false
      @comment.status = Asset::STATUS[:published]
      @comment.save!
      respond_to do |format|
        format.js do
          render :update do |page| 
              page["spam_#{params[:id].to_s}"].replace_html "Marked as not spam"
          end
        end
      end      
    end
  end

private

  def comments_open?
    return false unless asset = Asset.find(params[:comment][:asset_id])
    return asset.comments_open?
  end
  
  def authorized?
    current_user.is_admin?
  end
  
  def retrieve_comment
    @comment = Comment.find(params[:id])
  end  
end