# frozen_string_literal: true

class CalendarController < InertiaController
  def index
    # Compute the window to render occurrences for. The calendar grid
    # shows 6 rows of 7 cells (42 days), potentially spilling into the
    # previous/next month — expand a little further on each side so
    # neighbouring days also show dots when the user arrows around.
    center = params[:month].present? ? Date.parse(params[:month]).beginning_of_month : Date.today.beginning_of_month
    range_start = (center - 14).beginning_of_day
    range_end = (center.end_of_month + 14).end_of_day

    reminders = Current.user.reminders.order(start: :asc)
    occurrences = ReminderOccurrences.in_range(reminders, range_start: range_start.to_date, range_end: range_end.to_date)

    render inertia: {
      # `reminders` still ships so the day panel can pull title/notes/time
      # from the source record when an occurrence is selected.
      reminders: reminders,
      # Each occurrence is a cheap pair {reminder_id, date} — the frontend
      # uses `date` for the dot set and resolves `reminder_id` for details.
      occurrences: occurrences.map { |o| {reminder_id: o.reminder_id, date: o.date.iso8601} },
      today: Date.today.iso8601
    }
  end
end
