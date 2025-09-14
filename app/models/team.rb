class Team < ApplicationRecord
  belongs_to :league
  belongs_to :country
  has_many :users, foreign_key: 'team_id', dependent: :nullify
  
  validates :name, presence: true
  validates :symbol_slug, presence: true, uniqueness: true
  validates :color_primary, presence: true
  validates :color_secondary, presence: true
end
