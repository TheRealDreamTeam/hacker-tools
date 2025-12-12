class Tool < ApplicationRecord
  # Tools are community-owned top-level entities (ideas/topics like "React", "Git")
  # Users don't own tools - they submit content (submissions) about tools
  # Active Storage attachments
  has_one_attached :icon
  has_one_attached :picture

  # Associations
  has_many :submission_tools, dependent: :destroy
  has_many :submissions, through: :submission_tools # User-submitted content about this tool
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :tool_tags, dependent: :destroy
  has_many :tags, through: :tool_tags
  has_many :list_tools, dependent: :destroy
  has_many :lists, through: :list_tools
  has_many :user_tools, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy

  # Through associations for user interactions
  has_many :upvoters, -> { where(user_tools: { upvote: true }) }, through: :user_tools, source: :user
  has_many :favoriters, -> { where(user_tools: { favorite: true }) }, through: :user_tools, source: :user
  has_many :followers, through: :follows, source: :user

  # Use prefix to avoid clashing with Ruby's `public?`/`private?` methods.
  enum visibility: { public: 0, unlisted: 1, private: 2 }, _prefix: :visibility

  before_validation :set_tool_name_from_url
  after_create :enqueue_discovery_job

  validates :tool_name, presence: true
  # tool_url is optional - tools can exist without a URL (e.g., Elasticsearch could have multiple valid URLs)
  validate :tool_url_format
  validates :visibility, presence: true

  # Scopes for filtering
  scope :public_tools, -> { where(visibility: visibilities[:public]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_upvoted, -> { joins(:user_tools).where(user_tools: { upvote: true }).group("tools.id").order("COUNT(user_tools.id) DESC") }

  # Interaction helpers
  def user_tool_for(user)
    return nil unless user

    if user_tools.loaded?
      user_tools.find { |ut| ut.user_id == user.id }
    else
      user_tools.find_by(user: user)
    end
  end

  def upvoted_by?(user)
    user_tool_for(user)&.upvote?
  end

  def favorited_by?(user)
    user_tool_for(user)&.favorite?
  end

  def upvote_count
    user_tools.where(upvote: true).count
  end

  def favorite_count
    user_tools.where(favorite: true).count
  end

  def follower_count
    follows.count
  end

  private

  # Validate URL format - must be a valid HTTP/HTTPS URL
  def tool_url_format
    return if tool_url.blank?

    uri = URI.parse(tool_url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:tool_url, "must be a valid URL (e.g., https://example.com)")
    end
  rescue URI::InvalidURIError
    errors.add(:tool_url, "must be a valid URL (e.g., https://example.com)")
  end

  # Enqueue tool discovery job to enrich tool information from the internet
  def enqueue_discovery_job
    ToolDiscoveryJob.perform_later(id)
  end

  # Derive a placeholder tool name from the URL host so users only provide URL/author note.
  def set_tool_name_from_url
    return if tool_name.present? || tool_url.blank?

    uri_host = URI.parse(tool_url).host
    self.tool_name = uri_host&.sub(/\Awww\./, "") if uri_host.present?
  rescue URI::InvalidURIError
    # URL format validation will catch this and provide a clear error message
  end
end

