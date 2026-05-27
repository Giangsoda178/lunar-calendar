# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "Secret1*3*5*") }

  def inertia_headers
    {
      "X-Inertia" => "true",
      "X-Inertia-Version" => InertiaRails.configuration.version.to_s,
      "X-Requested-With" => "XMLHttpRequest",
      "Accept" => "text/html, application/xhtml+xml"
    }
  end

  describe "GET /sign_in" do
    it "returns success" do
      get sign_in_path, headers: inertia_headers

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /sign_in" do
    it "creates a session and redirects to the calendar" do
      expect do
        post sign_in_path, params: {
          email: " #{user.email.upcase} ",
          password: "Secret1*3*5*"
        }
      end.to change { user.sessions.count }.by(1)

      expect(response).to redirect_to(calendar_index_path)
    end

    it "resumes the session on the next request" do
      post sign_in_path, params: {
        email: user.email,
        password: "Secret1*3*5*"
      }

      get calendar_index_path, headers: inertia_headers

      expect(response).to have_http_status(:success)
    end

    it "rejects invalid credentials" do
      expect do
        post sign_in_path, params: {
          email: user.email,
          password: "SecretWrong1*3"
        }
      end.not_to change(Session, :count)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq("That email or password is incorrect")
    end
  end

  describe "DELETE /sign_out" do
    it "destroys the current session and redirects to sign in" do
      post sign_in_path, params: {
        email: user.email,
        password: "Secret1*3*5*"
      }

      session = user.sessions.last

      expect do
        delete sign_out_path
      end.to change(Session, :count).by(-1)

      expect(Session.exists?(session.id)).to be(false)
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
