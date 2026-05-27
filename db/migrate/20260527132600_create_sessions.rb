# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :string, force: :cascade do |t|
      t.references :user, null: false, foreign_key: true, type: :string
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
