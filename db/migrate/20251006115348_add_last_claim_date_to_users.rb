class AddLastClaimDateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_claim_date, :date
  end
end
