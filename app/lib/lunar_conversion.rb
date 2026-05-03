# frozen_string_literal: true

# Ruby port of Ho Ngoc Duc's Vietnamese lunar calendar algorithm, matched to
# the JS implementation in `@forvn/vn-lunar-calendar` so that backend and
# frontend agree on every conversion.
#
# We need this on the server (not just the client) so that:
#   - alert-scheduling jobs can expand yearly-lunar repeats into solar dates
#   - calendar responses can pre-compute occurrence dates without a JS round-trip
#
# Public API:
#   LunarConversion.solar_to_lunar(date)  -> { day:, month:, year:, leap: }
#   LunarConversion.lunar_to_solar(lunar_year, lunar_month, lunar_day, leap: false) -> Date
#
# Supported year range: 1200..2199 (matches the year tables in year_tables.rb).
module LunarConversion
  SUPPORTED_YEARS = (1200..2199).freeze

  # A single entry in a decoded lunar year — the first day of a lunar month.
  # `jd` is the Julian Day Number of that lunar 1st. Julian Day Numbers give us
  # a single monotonic integer per calendar day, which makes lunar-month lookup
  # a simple "find the largest jd <= target_jd" scan.
  LunarMonth = Struct.new(:day, :month, :year, :leap, :jd, keyword_init: true)

  class << self
    # Convert a Ruby Date (or anything with #year, #month, #day) to lunar.
    # Returns a Hash so the caller doesn't need to care about the internal struct.
    def solar_to_lunar(date)
      d, m, y = date.day, date.month, date.year
      raise ArgumentError, "year #{y} outside supported range" unless SUPPORTED_YEARS.cover?(y)

      # The lunar year that contains this solar date usually starts in the
      # previous solar year (Tet falls in Jan/Feb). If our solar date is
      # before the first lunar month of year `y`, we need year `y-1`'s info.
      ly = decode_year(y)
      jd = jdn(d, m, y)
      ly = decode_year(y - 1) if jd < ly.first.jd

      find_lunar_date(jd, ly).tap do |lunar|
        return {day: lunar.day, month: lunar.month, year: lunar.year, leap: lunar.leap}
      end
    end

    # Convert lunar (y, m, d[, leap]) to a Ruby Date.
    # `leap:` selects the leap-month variant when a year has a leap version of
    # the given month number (rare: one month per year, only some years).
    def lunar_to_solar(lunar_year, lunar_month, lunar_day, leap: false)
      raise ArgumentError, "year #{lunar_year} outside supported range" unless SUPPORTED_YEARS.cover?(lunar_year)

      ly = decode_year(lunar_year)

      # Look up the first day of the target lunar month. Leap months live
      # alongside a regular month with the same number; pick the right one.
      month_info = if leap
        ly.find { |m| m.month == lunar_month && m.leap } || raise(ArgumentError, "no leap month #{lunar_month} in lunar year #{lunar_year}")
      else
        ly.find { |m| m.month == lunar_month && !m.leap } || raise(ArgumentError, "no month #{lunar_month} in lunar year #{lunar_year}")
      end

      # JD for day `d` of this lunar month is the month-start JD plus offset.
      jd = month_info.jd + lunar_day - 1
      jdn_to_date(jd)
    end

    private

    # Julian Day Number from a Gregorian (or pre-1582 Julian) date. The
    # algorithm is standard and matches the JS library byte-for-byte.
    def jdn(day, month, year)
      a = ((14 - month) / 12).floor
      y = year + 4800 - a
      m = month + 12 * a - 3
      jd = day + ((153 * m + 2) / 5).floor + 365 * y + (y / 4).floor - (y / 100).floor + (y / 400).floor - 32045

      # Switch to Julian (not Gregorian) calendar before the 1582 reform cutoff.
      # 2299161 is the JD for 1582-10-15, the first Gregorian day.
      if jd < 2299161
        jd = day + ((153 * m + 2) / 5).floor + 365 * y + (y / 4).floor - 32083
      end

      jd
    end

    # Inverse of jdn — returns a Ruby Date.
    def jdn_to_date(jd)
      if jd < 2299161
        a = jd
      else
        alpha = ((jd - 1867216.25) / 36524.25).floor
        a = jd + 1 + alpha - (alpha / 4).floor
      end

      b = a + 1524
      c = ((b - 122.1) / 365.25).floor
      d_ = (365.25 * c).floor
      e = ((b - d_) / 30.6001).floor

      day = (b - d_ - (30.6001 * e).floor).to_i
      month = e < 14 ? e - 1 : e - 13
      year = month < 3 ? c - 4715 : c - 4716

      Date.new(year, month, day)
    end

    # Given a target JD, walk the decoded lunar year backwards until we find
    # the month it belongs to, then the day offset within that month.
    def find_lunar_date(jd, ly)
      i = ly.length - 1
      i -= 1 while jd < ly[i].jd
      off = jd - ly[i].jd
      LunarMonth.new(day: ly[i].day + off, month: ly[i].month, year: ly[i].year, leap: ly[i].leap, jd: jd)
    end

    # Decode the bitfield for a given solar year into an array of LunarMonth
    # entries (the 1st day of each lunar month, ordered by time).
    def decode_year(year)
      table = year_table(year)
      offset = index_into_table(year)
      code = table[offset]

      month_lengths = [29, 30]
      offset_of_tet = code >> 17                        # Jan 1 -> Tet offset in days
      leap_month = code & 0xf                           # 0 means no leap this year
      leap_month_length = month_lengths[(code >> 16) & 0x1]

      # Reconstruct 12 regular-month lengths from the 12 low bits (after the
      # leap flag): each bit is 0 => 29 days, 1 => 30 days.
      regular_months = Array.new(12)
      j = code >> 4
      12.times do |i|
        regular_months[12 - i - 1] = month_lengths[j & 0x1]
        j >>= 1
      end

      # Walk month-by-month from Tet, accumulating JDs.
      current_jd = jdn(1, 1, year) + offset_of_tet
      ly = []

      if leap_month.zero?
        (1..12).each do |mm|
          ly << LunarMonth.new(day: 1, month: mm, year: year, leap: false, jd: current_jd)
          current_jd += regular_months[mm - 1]
        end
      else
        # When there's a leap month, months 1..leap_month happen, then the
        # leap copy of leap_month, then leap_month+1..12.
        (1..leap_month).each do |mm|
          ly << LunarMonth.new(day: 1, month: mm, year: year, leap: false, jd: current_jd)
          current_jd += regular_months[mm - 1]
        end
        ly << LunarMonth.new(day: 1, month: leap_month, year: year, leap: true, jd: current_jd)
        current_jd += leap_month_length
        ((leap_month + 1)..12).each do |mm|
          ly << LunarMonth.new(day: 1, month: mm, year: year, leap: false, jd: current_jd)
          current_jd += regular_months[mm - 1]
        end
      end

      ly
    end

    # TK13 holds 1200-1299, TK14 holds 1300-1399, etc. Pick the right table
    # and the right index within it.
    def year_table(year)
      key =
        if year < 1300 then :tk13
        elsif year < 1400 then :tk14
        elsif year < 1500 then :tk15
        elsif year < 1600 then :tk16
        elsif year < 1700 then :tk17
        elsif year < 1800 then :tk18
        elsif year < 1900 then :tk19
        elsif year < 2000 then :tk20
        elsif year < 2100 then :tk21
        else :tk22
        end
      YearTables::TABLES.fetch(key)
    end

    def index_into_table(year)
      # Each century-table has its year-0 aligned at a multiple of 100
      # starting from 1200. year % 100 picks the right row.
      year % 100
    end
  end
end
