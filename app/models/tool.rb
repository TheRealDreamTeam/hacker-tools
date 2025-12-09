class Tool < ApplicationRecord
  # Owned by a user; attachments hold icon/picture assets via Active Storage.
  belongs_to :user

  # Active Storage attachments
  has_one_attached :icon
  has_one_attached :picture

  # Associations
  has_many :comments, dependent: :destroy
  has_many :tool_tags, dependent: :destroy
  has_many :tags, through: :tool_tags
  has_many :list_tools, dependent: :destroy
  has_many :lists, through: :list_tools
  has_many :user_tools, dependent: :destroy

  # Through associations for user interactions
  has_many :upvoters, -> { where(user_tools: { upvote: true }) }, through: :user_tools, source: :user
  has_many :favoriters, -> { where(user_tools: { favorite: true }) }, through: :user_tools, source: :user
  has_many :subscribers, -> { where(user_tools: { subscribe: true }) }, through: :user_tools, source: :user

  validates :tool_name, presence: true

  # Scopes for filtering
  scope :public_tools, -> { where(visibility: 0) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_upvoted, -> { joins(:user_tools).where(user_tools: { upvote: true }).group("tools.id").order("COUNT(user_tools.id) DESC") }
end

