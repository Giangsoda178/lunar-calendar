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
#  start         :datetime         not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :string           not null
#
# Indexes
#
#  index_reminders_on_is_lunar  (is_lunar)
#  index_reminders_on_start     (start)
#  index_reminders_on_user_id   (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Reminder, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
