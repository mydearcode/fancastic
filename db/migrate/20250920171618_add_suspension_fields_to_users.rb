class AddSuspensionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :suspended, :boolean
    add_column :users, :suspend_reason, :integer
    add_column :users, :suspend_date, :date
  end
end
