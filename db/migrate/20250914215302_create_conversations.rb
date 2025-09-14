class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.string :title
      t.datetime :last_message_at
      t.timestamps
    end
  end
end
