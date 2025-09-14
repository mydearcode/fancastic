class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string
    add_column :users, :team_id, :integer, null: true
    add_column :users, :energy, :integer, default: 100, null: false
    add_column :users, :message_privacy, :integer, default: 0, null: false
    add_column :users, :role, :integer, default: 0, null: false
    
    add_index :users, :username, unique: true
  end
end
