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

  # Use prefix to avoid clashing with Ruby's `public?`/`private?` methods.
  enum visibility: { public: 0, unlisted: 1, private: 2 }, _prefix: :visibility

  before_validation :set_tool_name_from_url

  validates :tool_name, presence: true
  validates :tool_url, presence: true
  validates :visibility, presence: true

  # Scopes for filtering
  scope :public_tools, -> { where(visibility: visibilities[:public]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_upvoted, -> { joins(:user_tools).where(user_tools: { upvote: true }).group("tools.id").order("COUNT(user_tools.id) DESC") }

  private

  # Derive a placeholder tool name from the URL host so users only provide URL/author note.
  def set_tool_name_from_url
    return if tool_name.present? || tool_url.blank?

    uri_host = URI.parse(tool_url).host
    self.tool_name = uri_host&.sub(/\Awww\./, "") if uri_host.present?
  rescue URI::InvalidURIError
    # Keep tool_name nil; validation will surface an error to the user if URL is invalid.
  end
end

