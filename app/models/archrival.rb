class Archrival < ApplicationRecord
  belongs_to :user
  belongs_to :rival_team, class_name: 'Team'
  
  validates :rival_team_id, uniqueness: { scope: :user_id }
  validate :rival_team_different_from_user_team
  
  private
  
  def rival_team_different_from_user_team
    if user && user.team_id == rival_team_id
      errors.add(:rival_team_id, "cannot be your own team")
    end
  end
end
