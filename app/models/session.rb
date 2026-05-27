# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id         :string           not null, primary key
#  ip_address :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :string           not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Session < ApplicationRecord
  include IdGenerator

  belongs_to :user

  before_validation :set_request_details, on: :create

  private

  def set_request_details
    self.user_agent ||= Current.user_agent
    self.ip_address ||= Current.ip_address
  end
end
