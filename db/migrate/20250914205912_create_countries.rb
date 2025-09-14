class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :flag_url
      t.string :color_primary
      t.string :color_secondary

      t.timestamps
    end
  end
end
