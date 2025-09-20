class CreateUserSuspensionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :user_suspension_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :suspended_by, null: false, foreign_key: { to_table: :users }
      t.references :unsuspended_by, null: true, foreign_key: { to_table: :users }
      t.datetime :suspended_at
      t.datetime :unsuspended_at, null: true

      t.timestamps
    end
  end
end
