class CreateFanPulseInteractionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :fan_pulse_interaction_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action_type
      t.string :target_type
      t.integer :target_id
      t.integer :energy_delta

      t.timestamps
    end
  end
end
