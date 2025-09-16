class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  belongs_to :team, optional: true
  
  # Profile images
  has_one_attached :profile_picture
  has_one_attached :cover_picture
  
  # Messaging associations
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  
  # Likes association
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  
  # Follow associations
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  
  # FanPulse energy system
  has_many :interaction_logs, class_name: 'FanPulse::InteractionLog', dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # Enums
  enum :message_privacy, { everyone: 0, followers: 1, nobody: 2 }
  enum :role, { user: 0, moderator: 1, admin: 2 }
  
  # Validations
  validates :username, presence: true, uniqueness: true
  validates :energy, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Energy management methods
  def can_perform_action?(action_type)
    energy_cost = FanPulse::InteractionLog::ENERGY_COSTS[action_type] || 0
    return true if energy_cost >= 0 # Restores are always allowed
    energy + energy_cost >= 0
  end
  
  def perform_action(action_type, target = nil)
    FanPulse::InteractionLog.log_interaction(self, action_type, target)
  end
  
  def energy_percentage
    (energy.to_f / 100 * 100).round
  end
  
  def low_energy?
    energy < 20
  end
  
  # Follow helper methods
  def follow(user)
    return false if user == self
    return false if following?(user)
    active_follows.create(followed: user)
  end
  
  def unfollow(user)
    active_follows.find_by(followed: user)&.destroy
  end
  
  def following?(user)
    following.include?(user)
  end
  
  def followers_count
    followers.count
  end
  
  def following_count
    following.count
  end
end
