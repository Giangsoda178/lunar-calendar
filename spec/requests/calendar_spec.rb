# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calendar", type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate).and_return(true)
    allow(Current).to receive(:user).and_return(user)
  end

  def inertia_headers
    {
      "X-Inertia" => "true",
      "X-Requested-With" => "XMLHttpRequest",
      "Accept" => "text/html, application/xhtml+xml"
    }
  end

  describe "GET /calendar" do
    it "returns month-scoped occurrences when month param is provided" do
      in_window = create(:reminder, user: user, title: "In window", start: Time.zone.parse("2026-06-20 09:00"), end: nil)
      create(:reminder, user: user, title: "Out of window", start: Time.zone.parse("2026-05-05 09:00"), end: nil)

      get calendar_index_path, params: {month: "2026-06-01"}, headers: inertia_headers

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body

      expect(payload["props"]["focused_date"]).to eq("2026-06-01")
      occurrence_ids = payload["props"]["occurrences"].map { |item| item["reminder_id"] }
      expect(occurrence_ids).to include(in_window.id)
      expect(occurrence_ids).not_to include(nil)
      out_of_window_occurrence = payload["props"]["occurrences"].find { |item| item["date"] == "2026-05-05" }
      expect(out_of_window_occurrence).to be_nil
    end

    it "falls back to default behavior for invalid month values" do
      get calendar_index_path, params: {month: "invalid-date"}, headers: inertia_headers

      expect(response).to have_http_status(:ok)
      payload = response.parsed_body
      expect(payload["props"]["focused_date"]).to be_nil
    end
  end
end
