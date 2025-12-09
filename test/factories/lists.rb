FactoryBot.define do
  factory :list do
    association :user
    sequence(:list_name) { |n| "List #{n}" }
    list_type { 0 }
    visibility { 0 }
  end
end

