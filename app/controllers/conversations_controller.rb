class ConversationsController < ApplicationController
  before_action :require_authentication
  before_action :set_conversation, only: [:show, :destroy]
  
  def index
    @conversations = Current.user.conversations
                                 .includes(:users, :messages)
                                 .recent
  end
  
  def show
    @messages = @conversation.messages.includes(:user).recent
    @message = Message.new
    
    # Mark conversation as read
    participant = @conversation.conversation_participants.find_by(user: Current.user)
    participant&.mark_as_read!
  end
  
  def new
    @conversation = Conversation.new
    @users = User.where.not(id: Current.user.id)
                 .where(message_privacy: ['everyone', 'followers'])
                 .order(:username)
    
    # Pre-select user if coming from their profile
    @selected_user_id = params[:user_id] if params[:user_id].present?
  end
  
  def create
    # Get selected participants
    participant_ids = params[:participant_ids]&.reject(&:blank?) || []
    
    # Prevent self-messaging
    if participant_ids.include?(Current.user.id.to_s)
      redirect_to new_conversation_path, alert: 'You cannot start a conversation with yourself.'
      return
    end
    
    # If no participants selected, prevent creating empty conversation
    if participant_ids.empty?
      redirect_to new_conversation_path, alert: 'Please select at least one participant.'
      return
    end
    
    # If only one participant is selected, check for existing conversation
    if participant_ids.length == 1
      target_user = User.find(participant_ids.first)
      
      # Check if user can be messaged
      unless can_message_user?(target_user)
        redirect_to new_conversation_path, alert: 'This user has disabled messages.'
        return
      end
      
      # Find existing conversation between these two users
      user_conversations = Current.user.conversations.includes(:users)
      existing_conversation = user_conversations.find do |conv|
        conv.users.count == 2 && conv.users.include?(target_user)
      end
      
      if existing_conversation
        redirect_to existing_conversation, notice: 'Opened existing conversation.'
        return
      end
    end
    
    # Create new conversation
    @conversation = Conversation.new
    
    if @conversation.save
      # Add current user as participant
      @conversation.conversation_participants.create!(user: Current.user)
      
      # Add selected participants
      if participant_ids.present?
        participant_ids.each do |user_id|
          user = User.find(user_id)
          next unless can_message_user?(user)
          @conversation.conversation_participants.create!(user: user)
        end
      end
      
      redirect_to @conversation, notice: 'Conversation was successfully created.'
    else
      @users = User.where.not(id: Current.user.id)
                   .where(message_privacy: ['everyone', 'followers'])
                   .order(:username)
      render :new, status: :unprocessable_entity
    end
  end
  
  def start_with_user
    target_user = User.find(params[:user_id])
    
    # Prevent self-messaging
    if target_user.id == Current.user.id
      redirect_to user_profile_path(target_user), alert: 'You cannot start a conversation with yourself.'
      return
    end
    
    # Check for blocking relationships
    if Current.user.blocked?(target_user) || Current.user.blocked_by?(target_user)
      redirect_to user_profile_path(target_user), alert: 'You cannot message this user due to blocking restrictions.'
      return
    end
    
    # Check if user can be messaged
    unless can_message_user?(target_user)
      redirect_to user_profile_path(target_user), alert: 'This user has disabled messages.'
      return
    end
    
    # Find existing conversation between these two users
    # Get all conversations where both users are participants
    user_conversations = Current.user.conversations.includes(:users)
    existing_conversation = user_conversations.find do |conv|
      conv.users.count == 2 && conv.users.include?(target_user)
    end
    
    if existing_conversation
      redirect_to existing_conversation
    else
      # Create new conversation
      @conversation = Conversation.create!
      @conversation.conversation_participants.create!(user: Current.user)
      @conversation.conversation_participants.create!(user: target_user)
      
      redirect_to @conversation, notice: 'Conversation started!'
    end
  end

  def destroy
    # Remove current user from conversation
    participant = @conversation.conversation_participants.find_by(user: Current.user)
    participant&.destroy
    
    # If no participants left, delete the conversation
    if @conversation.conversation_participants.empty?
      @conversation.destroy
    end
    
    redirect_to conversations_path, notice: 'Left conversation successfully.'
  end
  
  private
  
  def set_conversation
    @conversation = Current.user.conversations.find(params[:id])
  end
  
  def conversation_params
    params.require(:conversation).permit()
  end
  
  def can_message_user?(user)
    # Check if users have blocked each other
    return false if blocked_interaction?(user)
    
    case user.message_privacy
    when 'everyone'
      true
    when 'followers'
      # Check if target user is following the current user (karşılıklı takip)
      user.following?(Current.user)
    when 'team_mates'
      # Check if both users are on the same team or if target user is following current user
      (Current.user.team_id.present? && Current.user.team_id == user.team_id) || user.following?(Current.user)
    when 'nobody'
      false
    else
      false
    end
  end
end