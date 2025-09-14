class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :conversation_id }
  
  def mark_as_read!
    update(last_read_at: Time.current)
  end
  
  def unread_messages_count
    if last_read_at
      conversation.messages.where('created_at > ?', last_read_at).count
    else
      conversation.messages.count
    end
  end
end
