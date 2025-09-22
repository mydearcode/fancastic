class CreateEnergyCostSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :energy_cost_settings do |t|
      t.string :action_type, null: false
      t.integer :cost, null: false, default: 0
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :energy_cost_settings, :action_type, unique: true
    add_index :energy_cost_settings, :active

    # Seed initial data
    reversible do |dir|
      dir.up do
        EnergyCostSetting.create!([
          { action_type: 'like', cost: 1, description: 'Like işlemi' },
          { action_type: 'follow', cost: 2, description: 'Takip etme işlemi' },
          { action_type: 'post', cost: 5, description: 'Post oluşturma işlemi' },
          { action_type: 'repost', cost: 2, description: 'Repost işlemi' },
          { action_type: 'quote', cost: 3, description: 'Quote işlemi' },
          { action_type: 'reply', cost: 3, description: 'Reply işlemi' },
          { action_type: 'daily_restore', cost: -20, description: 'Günlük energy restore' }
        ])
      end
    end
  end
end