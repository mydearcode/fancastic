class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :content, presence: true, length: { maximum: 1000 }
  
  scope :recent, -> { order(:created_at) }
  
  after_create :update_conversation_timestamp
  
  private
  
  def update_conversation_timestamp
    conversation.update(last_message_at: created_at)
  end
end
