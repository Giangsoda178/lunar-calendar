# frozen_string_literal: true

Rails.application.routes.draw do
  root "home#index"

  get "kitchen_sink", to: "kitchen_sink#index"
  scope "kitchen_sink/mobile", as: :kitchen_sink_mobile do
    get "", to: "kitchen_sink_mobile#index", as: :index
    get "settings", to: "kitchen_sink_mobile#settings"
    get "profile", to: "kitchen_sink_mobile#profile"
    get "feed", to: "kitchen_sink_mobile#feed"
    get "components", to: "kitchen_sink_mobile#components"
  end

  # Playground for testing Inertia patterns
  scope :playground, as: :playground do
    get "", to: "playground#index", as: :index
    # Login form - basic authentication
    get "login-form", to: "playground#login_form", as: :login_form
    post "login-form", to: "playground#submit_login_form", as: :submit_login_form
    # Contact form - simple inquiry
    get "contact-form", to: "playground#contact_form", as: :contact_form
    post "contact-form", to: "playground#submit_contact_form", as: :submit_contact_form
    # User form - comprehensive with nested attributes
    get "user-form", to: "playground#user_form", as: :user_form
    post "user-form", to: "playground#submit_user_form", as: :submit_user_form
    # Navigation demo - preserveScroll/preserveState
    get "navigation-demo", to: "playground#navigation_demo", as: :navigation_demo
    # Advanced Inertia features demos
    get "data-loading", to: "playground#data_loading", as: :data_loading
    get "once-props", to: "playground#once_props", as: :once_props
    get "once-props/page2", to: "playground#once_props_page2", as: :once_props_page2
    get "realtime", to: "playground#realtime", as: :realtime
    get "lists-state", to: "playground#lists_state", as: :lists_state
    # WebSocket demo
    get "websocket", to: "playground#websocket", as: :websocket
    post "websocket/notify", to: "playground#send_notification", as: :send_notification
    # Email template playground
    get "emails", to: "playground#emails", as: :emails
    get "emails/preview", to: "playground#email_preview", as: :email_preview
    get "emails/partial-preview", to: "playground#partial_preview", as: :partial_preview
    post "emails/send", to: "playground#send_test_email", as: :send_test_email
  end

  scope :calendar, as: :calendar do
    get "", to: "calendar#index", as: :index
  end

  resources :reminders

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
