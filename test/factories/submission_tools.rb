# Factory for SubmissionTool join model
FactoryBot.define do
  factory :submission_tool do
    association :submission
    association :tool
  end
end

