# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_28_232401) do
  create_table "reminders", force: :cascade do |t|
    t.integer "alert_minutes"
    t.datetime "created_at", null: false
    t.datetime "end"
    t.boolean "is_lunar", default: false, null: false
    t.string "notes"
    t.datetime "start", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["is_lunar"], name: "index_reminders_on_is_lunar"
    t.index ["start"], name: "index_reminders_on_start"
    t.index ["user_id"], name: "index_reminders_on_user_id"
    t.check_constraint "end IS NULL OR end >= start", name: "chk_reminders_end_after_start"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name"
    t.string "password_digest"
    t.string "role", default: "user", null: false
    t.boolean "two_fa_enabled"
    t.string "two_fa_secret"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "reminders", "users"
end
