class CommentsController < ApplicationController
  include HermesControllerExtensions
  before_filter :login_required, :except => [ :create ]
  before_filter :comments_open?, :only => [:create, :edit]
  before_filter :retrieve_comment, :only => [:ham, :spam]
  
  def create
    comment = Comment.new(params[:comment])
    comment.status = Asset::STATUS[:draft] if comment.asset.moderate_comments?
    comment.created_by = current_user if logged_in?
    if comment.valid?
      defensio = Defensio.new(:no_validate_key => true)
      article = comment.asset.content
      if defensio.audit_comment(article, comment, :debug => true)
        comment.signature = defensio.response["signature"]
        comment.spam = defensio.response["spam"]
        comment.spaminess = defensio.response["spaminess"]
        comment.status = comment.spam? ? Asset::STATUS[:draft] : Asset::STATUS[:published]
      else
        logger.warning "Defensio failure: setting comment to draft"
        comment.status = Asset::STATUS[:draft]
      end
      flash[:notice] = "Your comment has been saved for moderation" if comment.status == Asset::STATUS[:draft] or comment.spam?
      flash[:notice] = "Comment not saved: #{comment.errors.full_messages.join(', ')}." unless comment.save
    else
      flash[:notice] = "Comment not saved: #{comment.errors.full_messages.join(', ')}"
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
      redirect_back_or_default('/')
    end
  end
  
  def edit
    
  end
  
  def spam
    defensio = Defensio.new(:no_validate_key => true)
    if defensio.report_false_positive(@comment)
      @comment.spam = true
      @comment.save!
      respond_to do |format|
        format.js do
          render :update do |page| 
              page["spam_#{params[:id].to_s}"].hide
              page["ham_#{params[:id].to_s}"].show
          end
        end
      end
    end
  end
  
  def ham
    defensio = Defensio.new(:no_validate_key => true)
    if defensio.report_false_negative(@comment)
      @comment.spam = false
      @comment.save!
      respond_to do |format|
        format.js do
          render :update do |page| 
              page["spam_#{params[:id].to_s}"].show
              page["ham_#{params[:id].to_s}"].hide
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