FactoryBot.define do
  factory :comment do
    association :tool
    association :user
    comment { "This is a test comment" }
    comment_type { 0 }
    visibility { 0 }
    solved { false }
  end
end

