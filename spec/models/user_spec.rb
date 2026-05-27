# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                         :string           not null, primary key
#  email                      :string           not null
#  email_verification_sent_at :datetime
#  email_verified_at          :datetime
#  first_name                 :string           not null
#  last_name                  :string
#  password_digest            :string
#  role                       :string           default("user"), not null
#  timezone                   :string           default("Asia/Ho_Chi_Minh"), not null
#  two_fa_enabled             :boolean
#  two_fa_secret              :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_users_on_email              (email) UNIQUE
#  index_users_on_email_verified_at  (email_verified_at)
#
require "rails_helper"

RSpec.describe User, type: :model do
  include ActiveJob::TestHelper

  it "tracks whether the email has been verified" do
    expect(build(:user, :unverified)).not_to be_verified
    expect(build(:user)).to be_verified
  end

  it "marks an email as verified" do
    user = create(:user, :unverified)

    expect { user.mark_email_verified! }
      .to change { user.reload.email_verified_at }
      .from(nil)
  end

  it "enqueues a verification email for unverified users" do
    user = create(:user, :unverified)

    expect do
      user.send_email_verification_later
    end.to have_enqueued_mail(TransactionalMailer, :email_verification)

    expect(user.reload.email_verification_sent_at).to be_present
  end

  it "does not enqueue a verification email for verified users" do
    user = create(:user)

    expect do
      user.send_email_verification_later
    end.not_to have_enqueued_mail(TransactionalMailer, :email_verification)
  end
end
