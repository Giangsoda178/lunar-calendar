# frozen_string_literal: true

module AuthenticationHelpers
  extend ActiveSupport::Concern

  def sign_in_as(user, password: "Secret1*3*5*")
    post sign_in_path, params: {email: user.email, password: password}
  end

  def sign_out
    delete sign_out_path
  end
end
