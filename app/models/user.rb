# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :string           not null, primary key
#  email           :string           not null
#  first_name      :string           not null
#  last_name       :string
#  password_digest :string
#  role            :string           default("user"), not null
#  two_fa_enabled  :boolean
#  two_fa_secret   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  include IdGenerator

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

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  private

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
