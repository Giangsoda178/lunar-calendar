# frozen_string_literal: true

class SessionsController < InertiaController
  skip_before_action :authenticate, only: %i[new create]
  before_action :require_no_authentication, only: %i[new create]

  def new
    render inertia: {form: Authentication::SignInForm.defaults}
  end

  def create
    form = Authentication::SignInForm.new(session_params)
    user = form.authenticate

    if user
      session = user.sessions.create!
      write_session_cookie(session, remember: form.remember_me)
      redirect_to calendar_index_path, notice: "Signed in successfully"
    else
      redirect_to sign_in_path,
                  alert: "That email or password is incorrect",
                  inertia: inertia_errors(form, full_messages: false)
    end
  end

  def destroy
    Current.session&.destroy
    Current.session = nil
    cookies.delete(:session_token)
    redirect_to sign_in_path, notice: "Signed out successfully"
  end

  private

  def session_params
    params.permit(:email, :password, :remember_me)
  end

  def write_session_cookie(session, remember:)
    payload = {value: session.id, httponly: true, same_site: :lax}
    if remember
      cookies.signed.permanent[:session_token] = payload
    else
      cookies.signed[:session_token] = payload
    end
  end
end
