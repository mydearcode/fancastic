class AddDeletedAtToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :deleted_at, :datetime
  end
end
