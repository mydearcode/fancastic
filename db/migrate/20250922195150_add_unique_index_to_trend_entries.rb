class AddUniqueIndexToTrendEntries < ActiveRecord::Migration[8.0]
  def change
    # Remove existing duplicates first
    execute <<-SQL
      DELETE FROM trend_entries 
      WHERE id NOT IN (
        SELECT MIN(id) 
        FROM trend_entries 
        GROUP BY phrase, "window", window_start, window_end
      )
    SQL
    
    # Add unique index to prevent future duplicates
    add_index :trend_entries, [:phrase, :window, :window_start, :window_end], 
              unique: true, 
              name: 'index_trend_entries_on_phrase_window_and_times'
  end
end
