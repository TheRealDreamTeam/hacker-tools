FactoryBot.define do
  factory :user_tool do
    association :user
    association :tool
    upvote { false }
    favorite { false }
    subscribe { false }
    read_at { nil }
  end
end

