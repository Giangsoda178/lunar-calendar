class CreateReminderAlertDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_alert_deliveries do |t|
      t.references :reminder, null: false, foreign_key: true
      t.datetime :occurrence_at, null: false
      t.datetime :notified_at, null: false

      t.timestamps
    end

    add_index :reminder_alert_deliveries, [:reminder_id, :occurrence_at], unique: true
    add_index :reminder_alert_deliveries, :notified_at
  end
end
