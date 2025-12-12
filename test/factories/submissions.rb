FactoryBot.define do
  factory :submission do
    association :user
    
    sequence(:submission_url) { |n| "https://example.com/article-#{n}" }
    author_note { "This is a great article about React" }
    sequence(:submission_name) { |n| "Example Article #{n}" }
    submission_description { "An example article description" }
    submission_type { :article }
    status { :pending }
    metadata { {} }
    
    trait :completed do
      status { :completed }
      processed_at { Time.current }
    end
    
    trait :processing do
      status { :processing }
    end
    
    trait :failed do
      status { :failed }
    end
    
    trait :rejected do
      status { :rejected }
    end
    
    trait :github_repo do
      submission_type { :github_repo }
      submission_url { "https://github.com/user/repo" }
    end
    
    trait :guide do
      submission_type { :guide }
      submission_url { "https://example.com/guide" }
    end
    
    trait :with_tool do
      after(:create) do |submission|
        submission.tools << create(:tool)
      end
    end
    
    trait :with_tools do
      after(:create) do |submission|
        submission.tools << create_list(:tool, 2)
      end
    end
  end
end

