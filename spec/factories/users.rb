# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :string           not null, primary key
#  email           :string
#  first_name      :string           not null
#  last_name       :string
#  password_digest :string
#  role            :string           default("user"), not null
#  two_fa_enabled  :boolean
#  two_fa_secret   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { "Secret1*3*5*" }
    two_fa_enabled { false }
    two_fa_secret { nil }
    role { "user" }
  end
end
