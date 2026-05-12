# frozen_string_literal: true

class AddTimezoneToUsers < ActiveRecord::Migration[8.1]
  def change
    # Default "Asia/Ho_Chi_Minh" because the app is primarily aimed at
    # Vietnamese lunar-calendar users. Settable per user from Settings.
    add_column :users, :timezone, :string, null: false, default: "Asia/Ho_Chi_Minh"
  end
end
