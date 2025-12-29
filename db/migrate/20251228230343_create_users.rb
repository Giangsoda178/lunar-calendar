# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :string, force: :cascade do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.string :email, index: {unique: true}, null: false
      t.string :password_digest
      t.boolean :two_fa_enabled
      t.string :two_fa_secret
      t.string :role, null: false, default: "user"

      t.timestamps
    end
  end
end
