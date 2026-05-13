# frozen_string_literal: true

class CalendarController < InertiaController
  def index
    month = parsed_month(params[:month])
    center = month || Date.today.beginning_of_month
    range_start = (center - 14).beginning_of_day
    range_end = (center.end_of_month + 14).end_of_day

    reminders = Current.user.reminders.order(start: :asc)
    occurrences = ReminderOccurrences.in_range(reminders, range_start: range_start.to_date, range_end: range_end.to_date)

    render inertia: {
      reminders: reminders,
      occurrences: occurrences.map { |o| {reminder_id: o.reminder_id, date: o.date.iso8601} },
      today: Date.today.iso8601,
      focused_date: month&.iso8601
    }
  end

  private

  def parsed_month(raw_value)
    return nil if raw_value.blank?

    Date.iso8601(raw_value).beginning_of_month
  rescue Date::Error
    nil
  end
end
