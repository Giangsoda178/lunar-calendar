# frozen_string_literal: true

# Expand a set of reminders into concrete dated occurrences for a given
# window. Non-repeating reminders yield 0 or 1 occurrence; repeating reminders
# yield N depending on the period, clamped by `repeat_ends_at` and the window.
#
# The calendar controller uses this to render occurrence-based dots/lists
# (instead of only the `start` date) and the alert scheduler uses it to
# decide which future firings need jobs.
#
# A single "occurrence" is just the original reminder paired with the
# specific date it falls on — callers that need a time-of-day can derive
# it from `reminder.start`'s hour/minute.
class ReminderOccurrences
  Occurrence = Struct.new(:reminder, :date, keyword_init: true) do
    def reminder_id = reminder.id
    # The datetime this occurrence fires at — preserves the original
    # time-of-day of the reminder but moved onto `date`.
    def at
      t = reminder.start
      Time.zone.local(date.year, date.month, date.day, t.hour, t.min, t.sec)
    end
  end

  class << self
    # Expand many reminders at once. Returns occurrences in the order the
    # reminders arrive; callers that want date-sorted output should sort.
    def in_range(reminders, range_start:, range_end:)
      reminders.flat_map { |r| occurrences_for(r, range_start, range_end) }
    end

    def occurrences_for(reminder, range_start, range_end)
      return [] if reminder.start.to_date > range_end

      if reminder.repeat?
        expand_repeat(reminder, range_start, range_end)
      else
        single_occurrence(reminder, range_start, range_end)
      end
    end

    private

    def single_occurrence(reminder, range_start, range_end)
      date = reminder.start.to_date
      return [] unless date.between?(range_start, range_end)
      [Occurrence.new(reminder: reminder, date: date)]
    end

    def expand_repeat(reminder, range_start, range_end)
      # Per-occurrence end: the earlier of the window end and repeat_ends_at.
      # `repeat_ends_at` is nil for "repeat forever" — fall back to range_end.
      stop_at = reminder.repeat_ends_at&.to_date
      effective_end = stop_at && stop_at < range_end ? stop_at : range_end
      return [] if reminder.start.to_date > effective_end

      case reminder.repeat_period.to_s
      when "daily"    then expand_daily(reminder, range_start, effective_end)
      when "weekly"   then expand_weekly(reminder, range_start, effective_end)
      when "monthly"  then expand_monthly(reminder, range_start, effective_end)
      when "yearly"   then expand_yearly(reminder, range_start, effective_end)
      else []
      end
    end

    # ——— Repeat-period expanders ———————————————————————————————————————

    def expand_daily(reminder, range_start, range_end)
      # Advance one day at a time, skipping days before the window opens.
      # For pathological "1 reminder, expand 10 years" cases this is O(days)
      # which is fine for the window sizes we render (6 weeks max).
      start_date = reminder.start.to_date
      first = [start_date, range_start].max
      (first..range_end).map { |d| Occurrence.new(reminder: reminder, date: d) }
    end

    def expand_weekly(reminder, range_start, range_end)
      # Jump straight to the first occurrence on/after the window open by
      # computing how many weeks we need to skip from the original start.
      start_date = reminder.start.to_date
      return [] if start_date > range_end
      weeks_to_skip = [(range_start - start_date).to_i, 0].max / 7
      current = start_date + weeks_to_skip * 7
      current += 7 while current < range_start
      build_series(reminder, current, range_end) { |d| d + 7 }
    end

    def expand_monthly(reminder, range_start, range_end)
      start_date = reminder.start.to_date
      current = start_date
      # Skip forward in month steps until we enter the window.
      current = next_month_on(current, start_date.day) while current < range_start
      build_series(reminder, current, range_end) { |d| next_month_on(d, start_date.day) }
    end

    # Step to the next same-day-of-month. If the target day doesn't exist
    # (e.g. Feb 30), clamp to the last day of that month — common iOS behavior.
    def next_month_on(date, target_day)
      next_month = date.next_month.beginning_of_month
      day = [target_day, next_month.end_of_month.day].min
      Date.new(next_month.year, next_month.month, day)
    end

    def expand_yearly(reminder, range_start, range_end)
      if reminder.is_lunar?
        expand_yearly_lunar(reminder, range_start, range_end)
      else
        expand_yearly_solar(reminder, range_start, range_end)
      end
    end

    def expand_yearly_solar(reminder, range_start, range_end)
      start_date = reminder.start.to_date
      # Start at the anniversary in range_start's year (or later if the
      # original start is after that anniversary).
      (range_start.year..range_end.year).filter_map do |y|
        candidate = anniversary_in(start_date, y)
        next if candidate.nil? || candidate < range_start || candidate > range_end
        next if candidate < start_date
        Occurrence.new(reminder: reminder, date: candidate)
      end
    end

    # Handles Feb 29: in non-leap years we clamp to Feb 28 so the reminder
    # still fires annually rather than silently skipping three years in four.
    def anniversary_in(original, target_year)
      if Date.valid_date?(target_year, original.month, original.day)
        Date.new(target_year, original.month, original.day)
      elsif original.month == 2 && original.day == 29
        Date.new(target_year, 2, 28)
      end
    end

    def expand_yearly_lunar(reminder, range_start, range_end)
      # Convert the original solar `start` to lunar ONCE, then iterate over
      # LUNAR years (not solar years) and convert each back to solar. A lunar
      # year may produce a solar date in the next calendar year (Tet typically
      # falls in Jan/Feb), so we widen the iteration by one year at each end.
      lunar_anchor = LunarConversion.solar_to_lunar(reminder.start.to_date)
      start_date = reminder.start.to_date
      ((range_start.year - 1)..(range_end.year + 1)).filter_map do |ly|
        solar = solar_for_lunar(ly, lunar_anchor)
        next unless solar
        next if solar < start_date
        next unless solar.between?(range_start, range_end)
        Occurrence.new(reminder: reminder, date: solar)
      end
    end

    def solar_for_lunar(lunar_year, anchor)
      LunarConversion.lunar_to_solar(lunar_year, anchor[:month], anchor[:day], leap: anchor[:leap])
    rescue ArgumentError
      # The original month/day may not exist in a given lunar year (e.g. a
      # leap-month birthday in a non-leap year). Skip rather than crash.
      nil
    end

    # Common generator: walk forward using the provided step block, emit
    # an occurrence per date until we pass `range_end`.
    def build_series(reminder, start_date, range_end)
      occurrences = []
      current = start_date
      while current <= range_end
        occurrences << Occurrence.new(reminder: reminder, date: current)
        current = yield(current)
      end
      occurrences
    end
  end
end
