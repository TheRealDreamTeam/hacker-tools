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

  # Scopes for filtering and sorting
  # NOTE: We keep these scopes simple and composable so they can be chained from
  # controllers depending on context (e.g., public-only, eager loading, etc.).
  scope :public_tools, -> { where(visibility: visibilities[:public]) }

  # Default "newest" ordering – used when we explicitly want recency
  scope :recent, -> { order(created_at: :desc) }

  # Alphabetical sorting by tool name (case-insensitive) – used as the default
  # for the tools index to give users a predictable, stable list.
  scope :alphabetical, -> { order(Arel.sql("LOWER(tool_name) ASC")) }

  # All‑time most upvoted tools. Uses a LEFT JOIN so tools without any
  # interactions still appear (with 0 upvotes) and are ordered last.
  scope :most_upvoted_all_time, lambda {
    left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
  }

  # Trending tools: most upvoted in the last 30 days. Mirrors the home page
  # definition so users see consistent behavior between home and the tools index.
  scope :trending, lambda {
    left_joins(:user_tools)
      .where("user_tools.upvote = ? AND user_tools.created_at >= ?", true, 30.days.ago)
      .select("tools.*, COUNT(user_tools.id) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
  }

  # New & Hot: tools created in the last 7 days, ordered by upvotes in that
  # window and then recency. This matches the "New & Hot" category on the home
  # page to avoid confusing users with different definitions.
  scope :new_hot, lambda {
    where("tools.created_at >= ?", 7.days.ago)
      .left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
  }

  # Most favorited: tools with the highest number of favorites (all time).
  scope :most_favorited, lambda {
    left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.favorite = true THEN 1 ELSE 0 END), 0) AS favorites_count")
      .group("tools.id")
      .order("favorites_count DESC, tools.created_at DESC")
  }

  # Most followed: tools with the highest follower counts.
  scope :most_followed, lambda {
    left_joins(:follows)
      .select("tools.*, COALESCE(COUNT(follows.id), 0) AS follows_count")
      .group("tools.id")
      .order("follows_count DESC, tools.created_at DESC")
  }

  # Get top tags for this tool, ranked by number of submissions that have both the tool and the tag
  # This gives us relevance: tags that appear frequently with this tool are more relevant
  # Returns tags with their submission counts (as a virtual attribute)
  def top_tags(limit: 10)
    # Get all tags associated with this tool
    tool_tag_ids = tags.pluck(:id)
    return [] if tool_tag_ids.empty?

    # Count submissions that have BOTH each tag AND this tool
    # Use parameterized SQL to prevent SQL injection (id is from database, limit is controlled)
    sql = <<-SQL.squish
      SELECT tags.*, 
             COUNT(DISTINCT submission_tags.submission_id) AS submission_count
      FROM tags
      INNER JOIN tool_tags ON tags.id = tool_tags.tag_id
      INNER JOIN submission_tags ON tags.id = submission_tags.tag_id
      INNER JOIN submission_tools ON submission_tags.submission_id = submission_tools.submission_id
      WHERE tool_tags.tool_id = ?
        AND submission_tools.tool_id = ?
      GROUP BY tags.id
      ORDER BY submission_count DESC, tags.tag_name ASC
      LIMIT ?
    SQL

    # Use sanitize_sql_array with proper parameterization (? placeholders, not $1)
    sanitized_sql = Tag.send(:sanitize_sql_array, [sql, id, id, limit])
    results = Tag.connection.execute(sanitized_sql)

    # Convert results to Tag objects with submission_count attribute
    tag_ids = results.map { |r| r["id"] }
    tags_hash = Tag.where(id: tag_ids).index_by(&:id)
    
    results.map do |row|
      tag = tags_hash[row["id"].to_i]
      if tag
        # Add submission_count as a virtual attribute
        tag.define_singleton_method(:submission_count) { row["submission_count"].to_i }
        tag
      end
    end.compact
  end

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

