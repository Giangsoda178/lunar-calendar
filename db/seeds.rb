# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "bcrypt"

puts "Seeding users..."

admin = User.find_or_initialize_by(email: "admin@test.com")
admin.first_name = "Admin"
admin.last_name = "User"
admin.password_digest ||= BCrypt::Password.create("Password123!")
admin.role = "admin"
admin.two_fa_enabled = false
admin.save!
puts "  - Admin user: ", admin.email

leo = User.find_or_initialize_by(email: "leo@test.com")
leo.first_name = "Leo"
leo.last_name = "Nguyen"
leo.password_digest ||= BCrypt::Password.create("Password123!")
leo.role = "user"
leo.two_fa_enabled = false
leo.save!
puts "  - User: ", leo.email

puts "Seeding reminders..."

# Non-lunar reminder for Leo
reminder1 = Reminder.find_or_initialize_by(title: "Doctor Appointment", user_id: leo.id)
reminder1.assign_attributes(
  notes: "Bring ID and insurance card",
  is_lunar: false,
  start: Time.current.change(hour: 14, min: 0, sec: 0),
  "end" => Time.current.change(hour: 15, min: 0, sec: 0),
  alert_minutes: 30
)
reminder1.save!
puts "  - Reminder for #{leo.email}: #{reminder1.title} (#{reminder1.start})"

# Lunar reminder for Admin
lunar_start = Time.current + 3.days
reminder2 = Reminder.find_or_initialize_by(title: "Lunar Festival", user_id: admin.id)
reminder2.assign_attributes(
  notes: "Lunar-based festival reminder",
  is_lunar: true,
  start: lunar_start,
  "end" => lunar_start + 2.hours,
  alert_minutes: 60
)
reminder2.save!
puts "  - Lunar reminder for #{admin.email}: #{reminder2.title} (#{reminder2.start})"

puts "Seeding complete."
