class CreateArchrivals < ActiveRecord::Migration[8.0]
  def change
    create_table :archrivals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :rival_team, null: false, foreign_key: { to_table: :teams }

      t.timestamps
    end
    add_index :archrivals, [:user_id, :rival_team_id], unique: true
  end
end
