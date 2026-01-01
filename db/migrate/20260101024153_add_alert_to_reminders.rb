# frozen_string_literal: true

class AddAlertToReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :reminders, :alert, :boolean
  end
end
