# frozen_string_literal: true

# == Schema Information
#
# Table name: reminders
#
#  id             :integer          not null, primary key
#  alert          :boolean          default(FALSE), not null
#  alert_minutes  :integer
#  deleted_at     :datetime
#  end            :datetime         not null
#  is_lunar       :boolean          default(FALSE), not null
#  notes          :string
#  repeat         :boolean          default(FALSE), not null
#  repeat_ends_at :datetime
#  repeat_period  :integer
#  start          :datetime         not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :string           not null
#
# Indexes
#
#  index_reminders_on_deleted_at     (deleted_at)
#  index_reminders_on_is_lunar       (is_lunar)
#  index_reminders_on_repeat_period  (repeat_period)
#  index_reminders_on_start          (start)
#  index_reminders_on_user_id        (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Reminder < ApplicationRecord
  include Discard::Model
  self.discard_column = :deleted_at
  default_scope -> { kept }

  belongs_to :user

  attribute :repeat_period, :integer
  enum(:repeat_period, {daily: 0, weekly: 1, monthly: 2, yearly: 3})

  validates :title, presence: true
  validates :start, presence: true
  validates :end, presence: true
  validates :is_lunar, inclusion: {in: [true, false]}
  validates :repeat, inclusion: {in: [true, false]}
  validates :repeat_period, presence: true, if: :repeat?
  validates :alert_minutes,
    numericality: {greater_than_or_equal_to: 0, only_integer: true},
    allow_nil: true
  validates :alert_minutes, presence: true, if: :alert?
  # repeat_ends_at can only be set when repeat is on — otherwise a lingering
  # value on a non-repeating reminder would be confusing (never read, never cleared).
  validates :repeat_ends_at, absence: true, unless: :repeat?
  validate :end_on_or_after_start
  validate :repeat_ends_at_after_start

  private

  def end_on_or_after_start
    return if self[:end].blank? || start.blank?
    errors.add(:end, "must be on or after start") if self[:end] < start
  end

  def repeat_ends_at_after_start
    return if repeat_ends_at.blank? || start.blank?
    errors.add(:repeat_ends_at, "must be on or after start") if repeat_ends_at < start
  end
end
