FactoryBot.define do
  factory :tool do
    association :user
    sequence(:tool_name) { |n| "Tool #{n}" }
    tool_description { "A useful tool" }
    tool_url { "https://example.com" }
    visibility { 0 }
  end
end

