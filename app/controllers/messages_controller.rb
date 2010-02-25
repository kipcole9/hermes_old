class MessagesController < ApplicationController
  before_filter :login_required, :except => [:create]
  before_filter :retrieve_messages
  
  def create
    @message =  Message.new(params[:message])
    if @message.save
      flash[:notice] = "Thanks for the message. They're checked frequently so we'll get back to you soon if you have a question or issue."
      redirect_back_or_default('/')
    else
      flash[:notice] = "#{@message.errors.full_messages.join('; ')}"
      @message = Message.new(params[:message])
      render :template => "publications/contact"
    end
  end
  
  def index
    respond_to do |format|
      format.rss
    end
  end

private
  def authorized?
    current_user.is_admin?
  end  
  
  def retrieve_messages
    @messages = Message.all
  end
  
end