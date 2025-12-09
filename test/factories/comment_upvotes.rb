FactoryBot.define do
  factory :comment_upvote do
    association :comment
    association :user
  end
end

