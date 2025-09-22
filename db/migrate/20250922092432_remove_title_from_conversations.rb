class RemoveTitleFromConversations < ActiveRecord::Migration[8.0]
  def change
    remove_column :conversations, :title, :string
  end
end
