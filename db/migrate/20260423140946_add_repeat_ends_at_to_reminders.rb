# frozen_string_literal: true

class AddRepeatEndsAtToReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :reminders, :repeat_ends_at, :datetime
  end
end
