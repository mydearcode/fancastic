class Report < ApplicationRecord
  belongs_to :reporter, class_name: 'User'
  belongs_to :reportable, polymorphic: true
  
  # Enums for report reasons and status
  enum :reason, { spam: 0, insult: 1, fraud: 2, impersonation: 3 }
  enum :status, { pending: 0, archived: 1, resolved: 2 }
  
  # Validations
  validates :reason, presence: true
  validates :status, presence: true
  
  # Default values
  after_initialize :set_defaults, if: :new_record?
  
  private
  
  def set_defaults
    self.status ||= :pending
  end
end
