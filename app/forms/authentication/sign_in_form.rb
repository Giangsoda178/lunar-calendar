# frozen_string_literal: true

module Authentication
  class SignInForm < ApplicationForm
    attribute :email, :string
    attribute :password, :string
    attribute :remember_me, :boolean, default: false

    validates :email, presence: true
    validates :password, presence: true
    validate :email_must_be_valid

    def authenticate
      return if invalid?

      user = User.find_by(email: normalized_email)
      return user if user&.authenticate(password)

      errors.add(:email, "or password is incorrect")
      nil
    end

    private

    def normalized_email
      email.to_s.strip.downcase
    end

    def email_must_be_valid
      return if email.blank?
      return if normalized_email.match?(User::VALID_EMAIL_REGEX)

      errors.add(:email, "is invalid")
    end
  end
end
