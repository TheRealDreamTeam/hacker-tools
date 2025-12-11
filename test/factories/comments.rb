FactoryBot.define do
  factory :comment do
    # Polymorphic association - can comment on Tool or Submission
    association :commentable, factory: :tool
    association :user
    comment { "This is a test comment" }
    comment_type { 0 }
    visibility { 0 }
    solved { false }
    
    trait :on_submission do
      association :commentable, factory: :submission
    end
    
    trait :on_tool do
      association :commentable, factory: :tool
    end
  end
end

