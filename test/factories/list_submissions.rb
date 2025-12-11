FactoryBot.define do
  factory :list_submission do
    association :list
    association :submission
  end
end

