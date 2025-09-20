class UserSuspensionLog < ApplicationRecord
  belongs_to :user
  belongs_to :suspended_by, class_name: 'User'
  belongs_to :unsuspended_by, class_name: 'User', optional: true

  scope :recent, -> { order(created_at: :desc) }
  
  # Enums
  enum :suspend_reason, { spam: 0, insult: 1, fraud: 2, impersonation: 3, moderator_action: 4 }
  
  # Kullanıcı adlarını döndüren yardımcı metodlar
  def user_username
    user&.username
  end
  
  def suspended_by_username
    suspended_by&.username
  end
  
  def unsuspended_by_username
    unsuspended_by&.username
  end
end