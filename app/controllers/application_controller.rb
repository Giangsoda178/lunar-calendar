# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_current_request_details
  before_action :authenticate

  private

  def authenticate
    return if perform_authentication
    return dev_auto_sign_in if Rails.env.local?

    redirect_to sign_in_path
  end

  def require_no_authentication
    return unless perform_authentication

    flash[:notice] = "You are already signed in"
    redirect_to root_path
  end

  def perform_authentication
    Current.session.present?
  end

  def dev_auto_sign_in
    user = User.first_or_create!(
      email: "dev@example.com",
      first_name: "Dev",
      last_name: "User",
      password: "Password123!"
    )
    Current.session = DevStubSession.new(user)
  end

  DevStubSession = Struct.new(:user) do
    def id = "dev-session"
    def as_json(...) = {id: id}
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end
end
