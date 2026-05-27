# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Email verifications", type: :request do
  include ActiveJob::TestHelper

  def sign_in(user)
    post sign_in_path, params: {
      email: user.email,
      password: "Secret1*3*5*"
    }
  end

  describe "GET /verify_email" do
    it "verifies a user with a valid token" do
      user = create(:user, :unverified)
      token = user.generate_token_for(:email_verification)

      expect do
        get verify_email_path(token: token)
      end.to change { user.reload.email_verified_at }.from(nil)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to eq("Your email has been verified")
    end

    it "rejects invalid tokens" do
      get verify_email_path(token: "invalid-token")

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq("That verification link is invalid or has expired")
    end

    it "does not verify with a stale token after verification state changes" do
      user = create(:user, :unverified)
      token = user.generate_token_for(:email_verification)
      user.mark_email_verified!

      get verify_email_path(token: token)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq("That verification link is invalid or has expired")
    end
  end

  describe "POST /email_verification" do
    it "resends verification email for the current unverified user" do
      user = create(:user, :unverified)
      sign_in(user)
      clear_enqueued_jobs

      expect do
        post email_verification_path
      end.to have_enqueued_mail(TransactionalMailer, :email_verification)

      expect(response).to redirect_to(calendar_index_path)
      expect(flash[:notice]).to eq("Verification email sent")
      expect(user.reload.email_verification_sent_at).to be_present
    end

    it "does not resend verification email for verified users" do
      user = create(:user)
      sign_in(user)

      expect do
        post email_verification_path
      end.not_to have_enqueued_mail(TransactionalMailer, :email_verification)

      expect(response).to redirect_to(calendar_index_path)
      expect(flash[:notice]).to eq("Your email is already verified")
    end
  end
end
