# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ReminderSync", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authenticate).and_return(true)
    allow(Current).to receive(:user).and_return(user)
  end

  describe "GET /reminders/sync" do
    it "returns current user reminders and occurrences only" do
      user_reminder = create(:reminder, user: user, title: "User reminder", start: Time.zone.parse("2026-05-10 09:00"), end: nil)
      create(:reminder, user: other_user, title: "Other reminder", start: Time.zone.parse("2026-05-10 10:00"), end: nil)

      get reminder_sync_path, params: {
        range_start: "2026-05-01",
        range_end: "2026-05-31"
      }, as: :json

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      reminder_ids = payload.fetch("reminders").map { |item| item.fetch("id") }
      expect(reminder_ids).to match_array([user_reminder.id])

      occurrence_ids = payload.fetch("occurrences").map { |item| item.fetch("reminder_id") }
      expect(occurrence_ids).to all(eq(user_reminder.id))
      expect(payload.fetch("window")).to include(
        "range_start" => "2026-05-01",
        "range_end" => "2026-05-31"
      )
    end
  end

  describe "POST /reminders/sync" do
    it "creates reminders from create operations" do
      expect do
        post reminder_sync_path, params: {
          operations: [
            {
              client_operation_id: "op-create-1",
              operation: "create",
              client_record_id: "local-1",
              attributes: {
                title: "Offline created",
                notes: "created while offline",
                start: "2026-05-11T08:30:00Z",
                is_lunar: false,
                alert: false,
                repeat: false
              }
            }
          ]
        }, as: :json
      end.to change { user.reminders.count }.by(1)

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.fetch("applied")).to include(
        include(
          "client_operation_id" => "op-create-1",
          "operation" => "create"
        )
      )
      expect(payload.fetch("failed")).to be_empty
      expect(payload.fetch("conflicts")).to be_empty
    end

    it "returns validation errors for invalid updates" do
      reminder = create(:reminder, user: user, title: "Original title", start: Time.zone.parse("2026-05-12 08:30"), end: nil)

      post reminder_sync_path, params: {
        operations: [
          {
            client_operation_id: "op-update-invalid",
            operation: "update",
            server_id: reminder.id,
            base_updated_at: reminder.updated_at.iso8601,
            attributes: {title: ""}
          }
        ]
      }, as: :json

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.fetch("applied")).to be_empty
      expect(payload.fetch("failed")).to include(
        include(
          "client_operation_id" => "op-update-invalid",
          "reason" => "validation"
        )
      )
      expect(payload.fetch("conflicts")).to be_empty
    end

    it "returns conflicts when base_updated_at is stale" do
      reminder = create(:reminder, user: user, title: "Original title", start: Time.zone.parse("2026-05-12 08:30"), end: nil)
      stale_time = (reminder.updated_at - 5.minutes).iso8601

      post reminder_sync_path, params: {
        operations: [
          {
            client_operation_id: "op-update-stale",
            operation: "update",
            server_id: reminder.id,
            base_updated_at: stale_time,
            attributes: {title: "Should conflict"}
          }
        ]
      }, as: :json

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.fetch("applied")).to be_empty
      expect(payload.fetch("failed")).to be_empty
      expect(payload.fetch("conflicts")).to include(
        include(
          "client_operation_id" => "op-update-stale",
          "server_id" => reminder.id,
          "reason" => "stale_record"
        )
      )
      expect(reminder.reload.title).to eq("Original title")
    end

    it "soft deletes reminders via discard semantics" do
      reminder = create(:reminder, user: user, title: "To delete", start: Time.zone.parse("2026-05-12 08:30"), end: nil)

      post reminder_sync_path, params: {
        operations: [
          {
            client_operation_id: "op-delete-1",
            operation: "delete",
            server_id: reminder.id,
            base_updated_at: reminder.updated_at.iso8601
          }
        ]
      }, as: :json

      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload.fetch("applied")).to include(
        include(
          "client_operation_id" => "op-delete-1",
          "operation" => "delete",
          "server_id" => reminder.id
        )
      )
      expect(payload.fetch("failed")).to be_empty
      expect(payload.fetch("conflicts")).to be_empty

      deleted = Reminder.unscoped.find(reminder.id)
      expect(deleted.deleted_at).to be_present
      expect(user.reminders.where(id: reminder.id)).to be_empty
    end
  end
end
