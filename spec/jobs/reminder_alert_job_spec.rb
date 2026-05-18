# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderAlertJob, type: :job do
  include ActiveJob::TestHelper

  around do |example|
    travel_to(Time.zone.parse("2026-05-12 11:00:00")) { example.run }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "notifies once for an upcoming reminder occurrence" do
    user = create(:user, timezone: "Australia/Hobart")
    reminder = create(
      :reminder,
      user: user,
      title: "Standup",
      start: Time.zone.parse("2026-05-12 11:08:00"),
      repeat: false,
      alert: true,
      alert_minutes: 10,
      "end" => nil
    )

    expect(ActionCable.server).to receive(:broadcast).with(
      NotificationsChannel.stream_name_for(user.id),
      hash_including(type: "info", title: "Reminder due soon", id: "reminder-#{reminder.id}-#{reminder.start.to_i}")
    )

    expect {
      described_class.perform_now
    }.to change(ReminderAlertDelivery, :count).by(1)
      .and have_enqueued_mail(NotificationMailer, :reminder).with(user, hash_including(subject: "Reminder: Standup"))
  end

  it "does not notify the same occurrence twice" do
    user = create(:user)
    create(
      :reminder,
      user: user,
      title: "Take medicine",
      start: Time.zone.parse("2026-05-12 11:05:00"),
      repeat: false,
      alert: true,
      alert_minutes: 10,
      "end" => nil
    )

    allow(ActionCable.server).to receive(:broadcast)

    expect { described_class.perform_now }.to change(ReminderAlertDelivery, :count).by(1)
    clear_enqueued_jobs

    expect(ActionCable.server).not_to receive(:broadcast)
    expect {
      described_class.perform_now
    }.not_to(change(ReminderAlertDelivery, :count))
    expect(enqueued_jobs).to be_empty
  end
end
