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
class User < ApplicationRecord
end
