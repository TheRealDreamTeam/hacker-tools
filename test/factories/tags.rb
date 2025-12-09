FactoryBot.define do
  factory :tag do
    sequence(:tag_name) { |n| "tag#{n}" }
    tag_description { "A tag description" }
    tag_type { 0 }
  end
end

