# frozen_string_literal: true

class CalendarController < InertiaController
  skip_before_action :authenticate

  def index
    # Get all reminders and group by date (ISO format YYYY-MM-DD)
    # Returns array of ISO date strings that have reminders
    # reminder_dates = Reminder.pluck(:start).map { |dt| dt.to_date.iso8601 }.uniq
    reminders = Reminder.all.order(start: :asc)
    render inertia: {
      # reminder_dates: reminder_dates,
      reminders: reminders,
      today: Date.today.iso8601
    }
  end
end
