class UserBlock < ApplicationRecord
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'

  # Validations
  validates :blocker_id, presence: true
  validates :blocked_id, presence: true
  validates :blocker_id, uniqueness: { scope: :blocked_id, message: "User is already blocked" }
  
  # Prevent self-blocking
  validate :cannot_block_self

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  private

  def cannot_block_self
    if blocker_id == blocked_id
      errors.add(:blocked_id, "You cannot block yourself")
    end
  end
end