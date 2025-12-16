FactoryBot.define do
  factory :tag do
    sequence(:tag_name) { |n| "tag#{n}" }
    sequence(:tag_slug) { |n| "tag-#{n}" }
    tag_description { "A tag description" }
    tag_type_id { 2 }
    tag_type { "Content Type" }
    tag_type_slug { "content-type" }
    color { "yellow" }
    icon { "📝" }
    tag_alias { nil }
    parent_id { nil }
  end
end

