class MessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_conversation
  
  def create
    @message = @conversation.messages.build(message_params)
    @message.user = Current.user
    
    if @message.save
      # Mark conversation as read for current user
      participant = @conversation.conversation_participants.find_by(user: Current.user)
      participant&.mark_as_read!
      
      redirect_to @conversation, notice: 'Message sent successfully.'
    else
      @messages = @conversation.messages.includes(:user).recent
      render 'conversations/show', status: :unprocessable_entity
    end
  end
  
  def destroy
    @message = @conversation.messages.find(params[:id])
    
    if @message.user == Current.user
      @message.destroy
      redirect_to @conversation, notice: 'Message deleted successfully.'
    else
      redirect_to @conversation, alert: 'You can only delete your own messages.'
    end
  end
  
  private
  
  def set_conversation
    @conversation = Current.user.conversations.find(params[:conversation_id])
  end
  
  def message_params
    params.require(:message).permit(:content)
  end
end