# frozen_string_literal: true

require "set"

class ReminderSyncController < ApplicationController
  def show
    reminders = Current.user.reminders.order(start: :asc)
    render json: snapshot_payload(reminders)
  end

  def create
    applied = []
    failed = []
    conflicts = []
    seen_operation_ids = Set.new

    operations.each do |operation|
      client_operation_id = operation[:client_operation_id].to_s
      next if client_operation_id.blank? || seen_operation_ids.include?(client_operation_id)

      seen_operation_ids << client_operation_id

      case operation[:operation]
      when "create"
        apply_create(operation, applied, failed)
      when "update"
        apply_update(operation, applied, failed, conflicts)
      when "delete"
        apply_delete(operation, applied, failed, conflicts)
      else
        failed << {
          client_operation_id: client_operation_id,
          reason: "invalid_operation",
          errors: {operation: ["must be one of create, update, delete"]}
        }
      end
    end

    reminders = Current.user.reminders.order(start: :asc)
    render json: snapshot_payload(reminders).merge(
      applied: applied,
      failed: failed,
      conflicts: conflicts
    )
  rescue ActionController::ParameterMissing => e
    render json: {
      applied: [],
      failed: [
        {
          client_operation_id: nil,
          reason: "bad_request",
          errors: {base: [e.message]}
        }
      ],
      conflicts: []
    }, status: :unprocessable_entity
  end

  private

  def operations
    params.require(:operations).map do |item|
      operation_params = item.is_a?(ActionController::Parameters) ? item : ActionController::Parameters.new(item.to_h)
      operation_params.permit(
        :client_operation_id,
        :operation,
        :client_record_id,
        :server_id,
        :base_updated_at,
        attributes: [
          :title, :notes, :start, :end, :is_lunar, :alert, :alert_minutes, :repeat, :repeat_period, :repeat_ends_at
        ]
      ).to_h.deep_symbolize_keys
    end
  end

  def apply_create(operation, applied, failed)
    reminder = Current.user.reminders.new(operation[:attributes] || {})

    if reminder.save
      applied << {
        client_operation_id: operation[:client_operation_id],
        operation: "create",
        client_record_id: operation[:client_record_id],
        server_id: reminder.id
      }
      return
    end

    failed << {
      client_operation_id: operation[:client_operation_id],
      reason: "validation",
      errors: reminder.errors.to_hash(true)
    }
  end

  def apply_update(operation, applied, failed, conflicts)
    reminder = find_server_reminder(operation[:server_id])
    if reminder.nil? || reminder.deleted_at.present?
      failed << {
        client_operation_id: operation[:client_operation_id],
        reason: "not_found",
        errors: {server_id: ["was not found"]}
      }
      return
    end

    if stale_update?(reminder, operation[:base_updated_at])
      conflicts << conflict_payload(operation, reminder)
      return
    end

    if reminder.update(operation[:attributes] || {})
      applied << {
        client_operation_id: operation[:client_operation_id],
        operation: "update",
        server_id: reminder.id
      }
      return
    end

    failed << {
      client_operation_id: operation[:client_operation_id],
      reason: "validation",
      errors: reminder.errors.to_hash(true)
    }
  end

  def apply_delete(operation, applied, failed, conflicts)
    reminder = find_server_reminder(operation[:server_id])
    if reminder.nil?
      applied << {
        client_operation_id: operation[:client_operation_id],
        operation: "delete",
        server_id: operation[:server_id]
      }
      return
    end

    if stale_update?(reminder, operation[:base_updated_at])
      conflicts << conflict_payload(operation, reminder)
      return
    end

    if reminder.deleted_at.nil?
      reminder.discard!
    end

    applied << {
      client_operation_id: operation[:client_operation_id],
      operation: "delete",
      server_id: reminder.id
    }
  rescue Discard::RecordNotDiscarded => e
    failed << {
      client_operation_id: operation[:client_operation_id],
      reason: "unknown",
      errors: {base: [e.message]}
    }
  end

  def find_server_reminder(server_id)
    return nil if server_id.blank?

    Reminder.unscoped.where(user: Current.user).find_by(id: server_id)
  end

  def stale_update?(reminder, base_updated_at)
    return false if base_updated_at.blank?

    base_time = Time.zone.parse(base_updated_at.to_s)
    return false if base_time.nil?

    reminder.updated_at.to_i > base_time.to_i
  rescue ArgumentError
    false
  end

  def conflict_payload(operation, reminder)
    {
      client_operation_id: operation[:client_operation_id],
      server_id: reminder.id,
      reason: "stale_record",
      server_updated_at: reminder.updated_at.iso8601
    }
  end

  def snapshot_payload(reminders)
    range_start, range_end = parse_range_window
    occurrences = ReminderOccurrences.in_range(reminders, range_start: range_start, range_end: range_end)

    {
      reminders: reminders.as_json,
      occurrences: occurrences.map { |occurrence| {reminder_id: occurrence.reminder_id, date: occurrence.date.iso8601} },
      window: {
        range_start: range_start.iso8601,
        range_end: range_end.iso8601
      }
    }
  end

  def parse_range_window
    if params[:range_start].present? && params[:range_end].present?
      range_start = Date.parse(params[:range_start].to_s)
      range_end = Date.parse(params[:range_end].to_s)
      range_start <= range_end ? [range_start, range_end] : [range_end, range_start]
    elsif params[:month].present?
      center = Date.parse(params[:month].to_s).beginning_of_month
      [(center - 14), (center.end_of_month + 14)]
    else
      center = Date.current.beginning_of_month
      [(center - 14), (center.end_of_month + 14)]
    end
  rescue Date::Error
    center = Date.current.beginning_of_month
    [(center - 14), (center.end_of_month + 14)]
  end
end
