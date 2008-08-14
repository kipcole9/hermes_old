class MessagesController < ApplicationController
  before_filter :login_required, :except => [:create]
  before_filter :retrieve_messages
  
  def create
    @message =  Message.new(params[:message])
    if @message.save
      flash[:notice] = "Your message has been sent and will be responded to shortly"
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