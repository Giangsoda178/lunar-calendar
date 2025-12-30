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
FactoryBot.define do
  factory :reminder do
    title { "MyString" }
    notes { "MyString" }
    is_lunar { false }
    start { "2025-12-29 10:24:01" }
    add_attribute(:end) { "2025-12-29 10:24:01" }
    alert_minutes { 1 }
  end
end
