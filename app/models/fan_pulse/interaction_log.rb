class FanPulse::InteractionLog < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true
  
  validates :action_type, presence: true
  validates :energy_delta, presence: true, numericality: true
  
  # Action types that consume or restore energy
  # This is kept for backward compatibility, but now reads from database
  def self.energy_costs
    @energy_costs ||= EnergyCostSetting.costs_hash.transform_values do |cost|
      # daily_restore should be positive (restores energy)
      # all other actions should be negative (consume energy)
      if cost < 0 # daily_restore is stored as negative, make it positive
        -cost
      else # other actions are stored as positive, make them negative
        -cost
      end
    end
  end

  # Legacy constant for backward compatibility
  ENERGY_COSTS = {
    'like' => -1,
    'follow' => -2,
    'post' => -5,
    'repost' => -2,
    'quote' => -3,
    'reply' => -3,
    'daily_restore' => 20
  }.freeze

  # Get energy cost for an action (reads from database first, falls back to constant)
  def self.energy_cost_for(action_type)
    cost = EnergyCostSetting.cost_for(action_type)
    
    # If we have a database setting, transform it properly
    if cost != 0
      # daily_restore should be positive (restores energy)
      # all other actions should be negative (consume energy)
      if action_type.to_s == 'daily_restore' && cost < 0
        return -cost # make positive
      elsif action_type.to_s != 'daily_restore' && cost > 0
        return -cost # make negative
      else
        return cost # already correct sign
      end
    end
    
    # Fallback to legacy constant
    ENERGY_COSTS[action_type.to_s] || 0
  end
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action_type: action) }
  
  # Log an interaction and update user's energy
  def self.log_interaction(user, action_type, target = nil)
    energy_cost = energy_cost_for(action_type)
    
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
