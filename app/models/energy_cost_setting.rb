class EnergyCostSetting < ApplicationRecord
  validates :action_type, presence: true, uniqueness: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: -100, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }

  # Get cost for a specific action type
  def self.cost_for(action_type)
    setting = find_by(action_type: action_type.to_s, active: true)
    setting&.cost || 0
  end

  # Get all costs as a hash (similar to the old ENERGY_COSTS constant)
  def self.costs_hash
    active.pluck(:action_type, :cost).to_h
  end

  # Update or create a cost setting
  def self.set_cost(action_type, cost, description = nil)
    setting = find_or_initialize_by(action_type: action_type.to_s)
    setting.cost = cost
    setting.description = description if description.present?
    setting.active = true
    setting.save!
    setting
  end

  # Bulk update costs
  def self.bulk_update_costs(costs_hash)
    transaction do
      costs_hash.each do |action_type, cost|
        set_cost(action_type, cost.to_i)
      end
    end
  end
end