# frozen_string_literal: true

class AddDeletedAtToReminders < ActiveRecord::Migration[8.1]
  def change
    add_column :reminders, :deleted_at, :datetime
    add_index :reminders, :deleted_at
  end
end
