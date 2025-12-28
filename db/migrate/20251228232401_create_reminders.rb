# frozen_string_literal: true

class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true, type: :string
      t.string :title, null: false
      t.string :notes
      t.boolean :is_lunar, null: false, default: false
      t.datetime :start, null: false
      t.datetime :end
      t.integer :alert_minutes

      t.timestamps
    end

    add_index :reminders, :start
    add_index :reminders, :is_lunar
    add_check_constraint :reminders, "end IS NULL OR end >= start", name: "chk_reminders_end_after_start"
  end
end
