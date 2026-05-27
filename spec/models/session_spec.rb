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
require "rails_helper"

RSpec.describe Session, type: :model do
  it "belongs to a user" do
    session = build(:session, user: nil)
    expect(session).not_to be_valid
  end

  it "captures request details from Current" do
    Current.user_agent = "Spec Browser"
    Current.ip_address = "192.0.2.10"

    session = create(:session, user_agent: nil, ip_address: nil)

    expect(session.user_agent).to eq("Spec Browser")
    expect(session.ip_address).to eq("192.0.2.10")
  ensure
    Current.reset
  end
end
