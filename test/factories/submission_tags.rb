FactoryBot.define do
  factory :submission_tag do
    association :submission
    association :tag
  end
end

