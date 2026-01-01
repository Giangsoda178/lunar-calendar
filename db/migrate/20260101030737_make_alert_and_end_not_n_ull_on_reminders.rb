# frozen_string_literal: true

class MakeAlertAndEndNotNUllOnReminders < ActiveRecord::Migration[8.1]
  def up
    # Set existing null alerts to false
    execute <<-SQL.squish
      UPDATE reminders
      SET alert = FALSE
      WHERE alert IS NULL
    SQL

    # Set default for alert and add NOT NULL constraints
    change_column_default :reminders, :alert, from: nil, to: false
    change_column_null :reminders, :alert, false
    change_column_null :reminders, :end, false
  end

  def down
    # Revert NOT NULL and default changes
    change_column_null :reminders, :end, true
    change_column_default :reminders, :alert, from: false, to: nil
    change_column_null :reminders, :alert, true
  end
end
