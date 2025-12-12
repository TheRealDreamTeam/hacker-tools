FactoryBot.define do
  factory :follow do
    association :user
    association :followable, factory: :tool
  end
end

