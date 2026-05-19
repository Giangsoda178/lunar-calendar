# frozen_string_literal: true

class ReminderAlertJob < ApplicationJob
  queue_as :default

  LOOKBACK = 1.minute

  def perform(now: Time.current)
    max_alert_minutes = Reminder.where(alert: true).where.not(alert_minutes: nil).maximum(:alert_minutes)
    return unless max_alert_minutes

    window_start = now - LOOKBACK
    window_end = now + max_alert_minutes.minutes

    alertable_reminders(window_start: window_start, window_end: window_end).find_each do |reminder|
      process_reminder(reminder, now: now, window_start: window_start, window_end: window_end)
    end
  end

  private

  def alertable_reminders(window_start:, window_end:)
    Reminder.includes(:user)
      .where(alert: true)
      .where.not(alert_minutes: nil)
      .where("start <= ?", window_end)
      .where("repeat = ? OR start >= ?", true, window_start)
      .where("repeat = ? OR repeat_ends_at IS NULL OR repeat_ends_at >= ?", false, window_start)
  end

  def process_reminder(reminder, now:, window_start:, window_end:)
    occurrences = ReminderOccurrences.occurrences_for(reminder, window_start.to_date, window_end.to_date)
    occurrences.each do |occurrence|
      occurrence_at = occurrence.at
      next unless occurrence_at.between?(window_start, window_end)
      next unless due_for_alert?(reminder: reminder, occurrence_at: occurrence_at, now: now)

      deliver_once(reminder: reminder, occurrence_at: occurrence_at, now: now)
    end
  end

  def due_for_alert?(reminder:, occurrence_at:, now:)
    alert_at = occurrence_at - reminder.alert_minutes.minutes
    alert_at <= now && now <= occurrence_at
  end

  def deliver_once(reminder:, occurrence_at:, now:)
    delivery = ReminderAlertDelivery.create!(
      reminder: reminder,
      occurrence_at: occurrence_at,
      notified_at: now
    )

    deliver_email(reminder: reminder, occurrence_at: occurrence_at)
    broadcast_notification(reminder: reminder, occurrence_at: occurrence_at)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    nil
  rescue StandardError
    delivery&.destroy
    raise
  end

  def deliver_email(reminder:, occurrence_at:)
    payload = reminder_payload(reminder: reminder, occurrence_at: occurrence_at)
    NotificationMailer.reminder(reminder.user, payload).deliver_later
  end

  def broadcast_notification(reminder:, occurrence_at:)
    ActionCable.server.broadcast(
      NotificationsChannel.stream_name_for(reminder.user_id),
      {
        id: "reminder-#{reminder.id}-#{occurrence_at.to_i}",
        type: "info",
        title: "Reminder due soon",
        message: reminder_message(reminder: reminder, occurrence_at: occurrence_at),
        timestamp: Time.current.iso8601
      }
    )
  end

  def reminder_payload(reminder:, occurrence_at:)
    {
      subject: "Reminder: #{reminder.title}",
      message: reminder_message(reminder: reminder, occurrence_at: occurrence_at),
      url: Rails.application.routes.url_helpers.calendar_index_url
    }
  end

  def reminder_message(reminder:, occurrence_at:)
    Time.use_zone(reminder.user.timezone.presence || Time.zone.name) do
      due_at = I18n.l(occurrence_at.in_time_zone, format: :long)
      "#{reminder.title} is due at #{due_at}."
    end
  end
end
