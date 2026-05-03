# frozen_string_literal: true

class AllowNullEndOnReminders < ActiveRecord::Migration[8.1]
  def change
    change_column_null :reminders, :end, true
  end
end
