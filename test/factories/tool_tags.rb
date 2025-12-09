FactoryBot.define do
  factory :tool_tag do
    association :tool
    association :tag
  end
end

