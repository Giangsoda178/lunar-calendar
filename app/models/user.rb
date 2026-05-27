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
class User < ApplicationRecord
  has_secure_password
  include IdGenerator

  generates_token_for :email_verification, expires_in: 2.days do
    [email, email_verified_at&.to_i].join(":")
  end

  has_many :sessions, dependent: :destroy
  has_many :reminders
  before_destroy { reminders.discard_all }

  attribute :role, :string
  enum :role, {admin: "admin", user: "user"}

  validates :first_name, presence: true
  validates :last_name, presence: true

  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/
  validates :email,
            presence: true,
            uniqueness: {case_sensitive: false},
            format: {with: VALID_EMAIL_REGEX}

  validates :password, length: {minimum: 8}, allow_nil: true
  validate :password_complexity, if: -> { password.present? }

  # Reject unknown strings so `Time.use_zone(user.timezone)` cannot raise mid-request.
  validate :timezone_must_be_recognized

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def name
    full_name
  end

  def verified
    email_verified_at.present?
  end

  def verified?
    verified
  end

  def mark_email_verified!
    update!(email_verified_at: Time.current)
  end

  def send_email_verification_later
    return if verified

    update!(email_verification_sent_at: Time.current)
    TransactionalMailer.email_verification(self, generate_token_for(:email_verification)).deliver_later
  end

  private

  def timezone_must_be_recognized
    return if timezone.blank?
    return if recognized_time_zone?(timezone)

    errors.add(:timezone, :inclusion)
  end

  def recognized_time_zone?(tz)
    return true if ActiveSupport::TimeZone[tz]

    TZInfo::Timezone.get(tz)
    true
  rescue TZInfo::InvalidTimezoneIdentifier
    false
  end

  def password_complexity
    return if password.blank?

    missing = []
    missing << "one uppercase letter" unless password.match?(/[A-Z]/)
    missing << "one lowercase letter" unless password.match?(/[a-z]/)
    missing << "one digit" unless password.match?(/\d/)
    missing << "one special character" unless password.match?(/[^A-Za-z0-9]/)

    return if missing.empty?

    errors.add(:password, "must include at least #{missing.to_sentence}")
  end

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }
end
