FactoryBot.define do
  factory :tool do
    # Tools are now community-owned (no user association)
    sequence(:tool_name) { |n| "Tool #{n}" }
    tool_description { "A useful tool" }
    tool_url { "https://example.com" }
    visibility { 0 }
  end
end

