# frozen_string_literal: true

module AuthenticationHelpers
  extend ActiveSupport::Concern

  def sign_in_as(user)
    session = user.sessions.create!
    cookies.signed.permanent[:session_token] = {value: session.id, httponly: true}
  end

  def sign_out
    cookies.delete(:session_token)
  end
end
