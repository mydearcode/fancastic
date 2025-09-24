class MessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_conversation
  
  def create
    # Check for blocking relationships with other conversation participants
    other_users = @conversation.users.where.not(id: Current.user.id)
    blocked_user = other_users.find { |user| Current.user.blocked?(user) || Current.user.blocked_by?(user) }
    
    if blocked_user
      redirect_to @conversation, alert: 'You cannot send messages due to blocking restrictions.'
      return
    end
    
    @message = @conversation.messages.build(message_params)
    @message.user = Current.user
    
    if @message.save
      # Mark conversation as read for current user
      participant = @conversation.conversation_participants.find_by(user: Current.user)
      if participant
        participant.mark_as_read!
        # Broadcast updated unread messages count for sender
        MessageService.broadcast_unread_count(Current.user)
      end
      
      # Send notification to other participants and broadcast their unread count
      other_participants = @conversation.users.where.not(id: Current.user.id)
      other_participants.each do |user|
        NotificationService.create_and_broadcast(
          user: user,
          notifiable: @message,
          message: "#{Current.user.username} sent you a message",
          title: "New Message"
        )
        # Broadcast updated unread messages count for receiver
        MessageService.broadcast_unread_count(user)
      end
      
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