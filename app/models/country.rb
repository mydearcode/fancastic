class Country < ApplicationRecord
  has_many :leagues, dependent: :destroy
  has_many :teams, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, length: { in: 2..3 }
  validates :color_primary, presence: true
  validates :color_secondary, presence: true
end
