# frozen_string_literal: true

class EmailVerificationsController < InertiaController
  skip_before_action :authenticate, only: :show

  def show
    user = User.find_by_token_for(:email_verification, params[:token].to_s)

    if user.nil?
      redirect_to sign_in_path, alert: "That verification link is invalid or has expired"
    elsif user.verified
      redirect_to sign_in_path, notice: "Your email is already verified"
    else
      user.mark_email_verified!
      TransactionalMailer.account_verified(user).deliver_later
      redirect_to sign_in_path, notice: "Your email has been verified"
    end
  end

  def create
    if Current.user.verified
      redirect_back fallback_location: calendar_index_path, notice: "Your email is already verified"
    else
      Current.user.send_email_verification_later
      redirect_back fallback_location: calendar_index_path, notice: "Verification email sent"
    end
  end
end
