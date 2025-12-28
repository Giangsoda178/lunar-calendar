FactoryBot.define do
  factory :reminder do
    title { "MyString" }
    notes { "MyString" }
    is_lunar { false }
    start { "2025-12-29 10:24:01" }
    end { "2025-12-29 10:24:01" }
    alert_minutes { 1 }
  end
end
