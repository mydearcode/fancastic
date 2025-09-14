class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :users, through: :conversation_participants
  has_many :messages, dependent: :destroy
  
  validates :title, length: { maximum: 255 }
  
  scope :recent, -> { order(last_message_at: :desc, updated_at: :desc) }
  
  def last_message
    messages.order(:created_at).last
  end
  
  def other_participants(current_user)
    users.where.not(id: current_user.id)
  end
  
  def display_title(current_user)
    return title if title.present?
    
    other_users = other_participants(current_user)
    if other_users.count == 1
      other_users.first.username
    else
      other_users.limit(3).pluck(:username).join(", ")
    end
  end
  
  def unread_count_for(user)
    participant = conversation_participants.find_by(user: user)
    return 0 unless participant
    
    if participant.last_read_at
      messages.where('created_at > ?', participant.last_read_at).count
    else
      messages.count
    end
  end
end
