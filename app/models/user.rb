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
  
  # Notifications
  has_many :notifications, dependent: :destroy
  
  # Likes association
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  
  # Follow associations
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower
  
  # Block associations
  has_many :user_blocks, class_name: 'UserBlock', foreign_key: 'blocker_id', dependent: :destroy
  has_many :blocking_relationships, class_name: 'UserBlock', foreign_key: 'blocker_id', dependent: :destroy
  has_many :blocked_by_relationships, class_name: 'UserBlock', foreign_key: 'blocked_id', dependent: :destroy
  has_many :blocked_users, through: :blocking_relationships, source: :blocked
  has_many :blocking_users, through: :blocked_by_relationships, source: :blocker
  
  # FanPulse energy system
  has_many :interaction_logs, class_name: 'FanPulse::InteractionLog', dependent: :destroy
  
  # Suspension logs
  has_many :suspension_logs, class_name: 'UserSuspensionLog', dependent: :destroy
  has_many :suspended_users, class_name: 'UserSuspensionLog', foreign_key: 'suspended_by_id'
  has_many :unsuspended_users, class_name: 'UserSuspensionLog', foreign_key: 'unsuspended_by_id'

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # Enums
  enum :message_privacy, { everyone: 0, followers: 1, team_mates: 2, nobody: 3 }
  enum :role, { user: 0, moderator: 1, admin: 2 }
  enum :suspend_reason, { spam: 0, insult: 1, fraud: 2, impersonation: 3, moderator_action: 4, harassment: 5, inappropriate: 6, other: 7 }
  
  # Reports
  has_many :reports, foreign_key: 'reporter_id', dependent: :nullify
  has_many :reported_as, as: :reportable, class_name: 'Report', dependent: :destroy
  
  # Search scope for users by name
  scope :search_by_name, ->(query) {
    return none if query.blank?
    where("username ILIKE ? OR full_name ILIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Archrivals
  has_many :archrivals, dependent: :destroy
  has_many :rival_teams, through: :archrivals
  validate :maximum_two_archrivals
  
  def maximum_two_archrivals
    if archrivals.size > 2
      errors.add(:base, "En fazla 2 ezeli rakip seçebilirsiniz")
    end
  end
  
  # Primary rival team (first one)
  def rival_team
    rival_teams.first
  end
  
  # Suspension methods
  def suspend!(reason)
    update(suspended: true, suspend_reason: reason, suspend_date: Date.today)
  end
  
  def unsuspend!
    update(suspended: false, suspend_reason: nil, suspend_date: nil)
  end
  
  def suspended?
    suspended
  end
  
  # Validations
  validates :username, 
    presence: true, 
    uniqueness: { case_sensitive: false },
    length: { in: 4..15, message: "4-15 karakter arasında olmalıdır" },
    format: { 
      with: /\A[a-zA-Z0-9_]+\z/, 
      message: "sadece harf, rakam ve alt çizgi (_) içerebilir" 
    },
    exclusion: { 
      in: %w[admin twitter root api www help support about terms privacy policy contact fancastic app mobile web ios android],
      message: "bu kullanıcı adı kullanılamaz" 
    }
  validates :energy, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Energy management methods
  def can_perform_action?(action_type)
    energy_cost = FanPulse::InteractionLog.energy_cost_for(action_type)
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
  
  # Block helper methods
  def block(user)
    return false if user == self
    return false if blocked?(user)
    blocking_relationships.create(blocked: user)
  end
  
  def unblock(user)
    blocking_relationships.find_by(blocked: user)&.destroy
  end
  
  def blocked?(user)
    blocked_users.include?(user)
  end
  
  def blocked_by?(user)
    blocking_users.include?(user)
  end
  
  def blocked_users_count
    blocked_users.count
  end
  
  # Helper methods for getting blocked user IDs
  def blocked_user_ids
    blocked_users.pluck(:id)
  end
  
  def blocking_user_ids
    blocking_users.pluck(:id)
  end
  
  # Unread messages count
  def unread_messages_count
    total_unread = 0
    conversations.includes(:conversation_participants, :messages).each do |conversation|
      participant = conversation.conversation_participants.find_by(user: self)
      next unless participant
      
      if participant.last_read_at
        total_unread += conversation.messages.where('created_at > ?', participant.last_read_at).count
      else
        total_unread += conversation.messages.count
      end
    end
    total_unread
  end
end
