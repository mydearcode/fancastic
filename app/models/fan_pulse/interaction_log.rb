class FanPulse::InteractionLog < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true
  
  validates :action_type, presence: true
  validates :energy_delta, presence: true, numericality: true
  
  # Action types that consume or restore energy
  ENERGY_COSTS = {
    'like' => -1,
    'follow' => -2,
    'post' => -5,
    'repost' => -2,
    'quote' => -3,
    'reply' => -3,
    'daily_restore' => 20
  }.freeze
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action_type: action) }
  
  # Log an interaction and update user's energy
  def self.log_interaction(user, action_type, target = nil)
    energy_cost = ENERGY_COSTS[action_type] || 0
    
    # Don't allow actions that would make energy negative (except restores)
    return false if energy_cost < 0 && user.energy + energy_cost < 0
    
    transaction do
      # Create the log entry
      log = create!(
        user: user,
        action_type: action_type,
        target: target,
        energy_delta: energy_cost
      )
      
      # Update user's energy
      user.update!(energy: [user.energy + energy_cost, 100].min)
      
      log
    end
  end
end
