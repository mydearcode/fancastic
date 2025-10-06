class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  
  # Helper method to get a setting value
  def self.get(key)
    find_by(key: key)&.value
  end
  
  # Helper method to set a setting value
  def self.set(key, value, description = nil)
    setting = find_or_initialize_by(key: key)
    setting.value = value
    setting.description = description if description
    setting.save!
    setting
  end
  
  # Get daily claim amount (default 20 if not set)
  def self.daily_claim_amount
    get('daily_claim_amount')&.to_i || 20
  end
end
