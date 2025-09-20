class AddSuspendReasonToUserSuspensionLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :user_suspension_logs, :suspend_reason, :integer
  end
end