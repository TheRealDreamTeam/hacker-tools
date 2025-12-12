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

