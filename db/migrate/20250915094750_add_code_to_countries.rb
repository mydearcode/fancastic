class AddCodeToCountries < ActiveRecord::Migration[8.0]
  def change
    add_column :countries, :code, :string
  end
end
