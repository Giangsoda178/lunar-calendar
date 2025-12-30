# frozen_string_literal: true

class AddRepeatToReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :reminders, :repeat, :boolean, default: false, null: false
    add_column :reminders, :repeat_period, :integer
    add_index :reminders, :repeat_period
  end
end
