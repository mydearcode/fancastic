class CreateTrendEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :trend_entries do |t|
      t.string :phrase
      t.integer :count
      t.string :window
      t.datetime :window_start
      t.datetime :window_end

      t.timestamps
    end
    add_index :trend_entries, :window
  end
end
