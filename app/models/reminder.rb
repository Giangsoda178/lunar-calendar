# frozen_string_literal: true

# == Schema Information
#
# Table name: reminders
#
#  id            :integer          not null, primary key
#  alert_minutes :integer
#  end           :datetime
#  is_lunar      :boolean          default(FALSE), not null
#  notes         :string
#  repeat        :boolean          default(FALSE), not null
#  repeat_period :integer
#  start         :datetime         not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :string           not null
#
# Indexes
#
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
  belongs_to :user

  attribute :repeat_period, :integer
  enum(:repeat_period, {daily: 0, weekly: 1, monthly: 2, yearly: 3})

  validates :title, presence: true
  validates :start, presence: true
  validates :is_lunar, inclusion: {in: [true, false]}
  validates :repeat, inclusion: {in: [true, false]}
  validates :repeat_period, presence: true, if: :repeat?
end
