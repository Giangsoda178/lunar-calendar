# frozen_string_literal: true

# == Schema Information
#
# Table name: reminder_alert_deliveries
#
#  id            :integer          not null, primary key
#  notified_at   :datetime         not null
#  occurrence_at :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  reminder_id   :integer          not null
#
# Indexes
#
#  idx_on_reminder_id_occurrence_at_385be13440     (reminder_id,occurrence_at) UNIQUE
#  index_reminder_alert_deliveries_on_notified_at  (notified_at)
#  index_reminder_alert_deliveries_on_reminder_id  (reminder_id)
#
# Foreign Keys
#
#  reminder_id  (reminder_id => reminders.id)
#
class ReminderAlertDelivery < ApplicationRecord
  belongs_to :reminder

  validates :occurrence_at, presence: true
  validates :notified_at, presence: true
  validates :occurrence_at, uniqueness: {scope: :reminder_id}
end
