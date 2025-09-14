class League < ApplicationRecord
  belongs_to :country
  has_many :teams, dependent: :destroy
  
  validates :name, presence: true
end
