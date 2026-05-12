# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderOccurrences do
  describe ".occurrences_for" do
    let(:user) { create(:user) }

    it "expands monthly lunar repeats by lunar month, not Gregorian month" do
      start_time = Time.zone.parse("2025-03-15 10:00")
      reminder = build(
        :reminder,
        {
          user: user,
          title: "Lunar monthly",
          start: start_time,
          repeat: true,
          repeat_period: :monthly,
          is_lunar: true,
          repeat_ends_at: nil,
          "end" => nil,
        },
      )

      lunar = LunarConversion.solar_to_lunar(start_time.to_date)
      next_l = LunarConversion.advance_lunar_month(
        year: lunar[:year],
        month: lunar[:month],
        day: lunar[:day],
        leap: lunar[:leap],
      )
      expected_second = LunarConversion.lunar_to_solar(
        next_l[:year],
        next_l[:month],
        next_l[:day],
        leap: next_l[:leap],
      )

      oc = described_class.occurrences_for(
        reminder,
        Date.new(2025, 3, 1),
        Date.new(2025, 6, 30),
      )
      dates = oc.map(&:date).uniq.sort

      expect(dates.first).to eq(start_time.to_date)
      expect(dates.second).to eq(expected_second)
    end

    it "still expands monthly solar repeats on Gregorian same-day-of-month" do
      start_time = Time.zone.parse("2025-03-15 10:00")
      reminder = build(
        :reminder,
        {
          user: user,
          title: "Solar monthly",
          start: start_time,
          repeat: true,
          repeat_period: :monthly,
          is_lunar: false,
          repeat_ends_at: nil,
          "end" => nil,
        },
      )

      oc = described_class.occurrences_for(
        reminder,
        Date.new(2025, 3, 1),
        Date.new(2025, 6, 30),
      )
      dates = oc.map(&:date).uniq.sort

      expect(dates).to eq(
        [
          Date.new(2025, 3, 15),
          Date.new(2025, 4, 15),
          Date.new(2025, 5, 15),
          Date.new(2025, 6, 15),
        ],
      )
    end
  end
end
