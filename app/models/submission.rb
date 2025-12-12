class Submission < ApplicationRecord
  # Include pg_search for full-text search
  include PgSearch::Model
  
  # User ownership - submissions belong to users
  belongs_to :user
  
  # Tool associations - submissions can be about multiple tools (many-to-many)
  has_many :submission_tools, dependent: :destroy
  has_many :tools, through: :submission_tools
  
  # Duplicate detection - self-referential
  belongs_to :duplicate_of, class_name: "Submission", optional: true
  has_many :duplicates, class_name: "Submission", foreign_key: "duplicate_of_id", dependent: :nullify
  
  # Associations with other models
  has_many :submission_tags, dependent: :destroy
  has_many :tags, through: :submission_tags
  has_many :list_submissions, dependent: :destroy
  has_many :lists, through: :list_submissions
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :follows, as: :followable, dependent: :destroy
  has_many :followers, through: :follows, source: :user
  
  # Active Storage attachments (for future use - images, etc.)
  has_one_attached :icon
  has_one_attached :picture
  
  # Submission type enum - various types of content users can submit
  enum submission_type: {
    article: 0,          # Blog post, article, tutorial
    guide: 1,            # How-to guide, tutorial
    documentation: 2,    # Official documentation
    github_repo: 3,      # GitHub repository (can be user's own repo)
    social_post: 4,      # Twitter/X, LinkedIn, etc. (external link)
    code_snippet: 5,     # Code example, gist
    website: 6,          # Company/product website
    video: 7,            # YouTube, Vimeo, etc.
    podcast: 8,          # Podcast episode
    post: 9,             # Text-only post (like Twitter post) - future feature
    other: 10            # Catch-all
  }
  
  # Status enum - tracks processing pipeline state
  enum status: {
    pending: 0,      # Just created, waiting for processing
    processing: 1,  # Currently being processed
    completed: 2,    # Processing complete
    failed: 3,        # Processing failed
    rejected: 4      # Rejected (duplicate, unsafe, etc.)
  }
  
  # Validations
  validates :user_id, presence: true
  validates :submission_type, presence: true
  validates :status, presence: true
  validates :normalized_url, uniqueness: { scope: :user_id, allow_nil: true }, if: -> { normalized_url.present? }
  validate :submission_url_format, if: -> { submission_url.present? }
  
  # Callbacks
  before_validation :normalize_url, if: -> { submission_url.present? }
  before_validation :set_default_status, on: :create
  
  # pg_search configuration for full-text search
  # Search across submission_name, submission_description, and author_note
  # Uses trigram for fuzzy matching and ranks results by relevance
  pg_search_scope :search_by_text,
                  against: {
                    submission_name: "A",
                    submission_description: "B",
                    author_note: "C"
                  },
                  using: {
                    tsearch: { prefix: true }, # Prefix matching for partial words
                    trigram: { threshold: 0.3 } # Fuzzy matching with trigram similarity
                  },
                  ranked_by: ":trigram"
  
  # Scopes
  scope :pending, -> { where(status: statuses[:pending]) }
  scope :processing, -> { where(status: statuses[:processing]) }
  scope :completed, -> { where(status: statuses[:completed]) }
  scope :failed, -> { where(status: statuses[:failed]) }
  scope :rejected, -> { where(status: statuses[:rejected]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(submission_type: submission_types[type]) }
  scope :for_tool, ->(tool) { joins(:submission_tools).where(submission_tools: { tool_id: tool.id }) }
  
  # Engagement scopes for home page categories
  # Trending: Most followed submissions in the last 30 days
  scope :trending, -> {
    joins(:follows)
      .where("follows.created_at >= ?", 30.days.ago)
      .where(status: statuses[:completed])
      .select("submissions.*, COUNT(follows.id) AS followers_count")
      .group("submissions.id")
      .order("followers_count DESC, submissions.created_at DESC")
  }
  
  # New & Hot: Submissions created in last 7 days, ranked by followers
  scope :new_hot, -> {
    where("submissions.created_at >= ?", 7.days.ago)
      .where(status: statuses[:completed])
      .left_joins(:follows)
      .select("submissions.*, COALESCE(COUNT(follows.id), 0) AS followers_count")
      .group("submissions.id")
      .order("followers_count DESC, submissions.created_at DESC")
  }
  
  # Most Followed: Submissions with most followers total
  scope :most_followed, -> {
    where(status: statuses[:completed])
      .left_joins(:follows)
      .select("submissions.*, COALESCE(COUNT(follows.id), 0) AS followers_count")
      .group("submissions.id")
      .order("followers_count DESC, submissions.created_at DESC")
  }
  
  # Helper methods for status checks
  def processing?
    status == "processing"
  end
  
  def completed?
    status == "completed"
  end
  
  def failed?
    status == "failed"
  end
  
  def rejected?
    status == "rejected"
  end
  
  def pending?
    status == "pending"
  end
  
  # Check if submission is a duplicate
  def duplicate?
    duplicate_of_id.present?
  end
  
  # Get follower count
  def follower_count
    follows.count
  end
  
  # Get metadata value
  def metadata_value(key)
    metadata[key.to_s]
  end
  
  # Set metadata value
  def set_metadata_value(key, value)
    self.metadata = metadata.merge(key.to_s => value)
  end
  
  private
  
  # Normalize URL for duplicate detection
  # Smart normalization that preserves content-identifying query params and path segments
  # Removes: www prefix, fragments, tracking/analytics params (utm_*, ref, source, etc.)
  # Keeps: path segments, content-identifying query params (id, v, status, etc.)
  def normalize_url
    return if submission_url.blank?
    
    begin
      uri = URI.parse(submission_url)
      # Only normalize HTTP/HTTPS URLs
      return unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      
      # Remove www prefix from host
      uri.host = uri.host&.sub(/\Awww\./, "")
      
      # Remove fragment (hash anchors are not content identifiers)
      uri.fragment = nil
      
      # Smart query param filtering: remove tracking params, keep content identifiers
      if uri.query.present?
        query_params = URI.decode_www_form(uri.query).to_h
        # Remove common tracking/analytics params
        tracking_params = %w[utm_source utm_medium utm_campaign utm_term utm_content ref source medium campaign fbclid gclid]
        filtered_params = query_params.reject { |key, _| tracking_params.include?(key.downcase) }
        
        # Rebuild query string if there are remaining params
        if filtered_params.any?
          uri.query = URI.encode_www_form(filtered_params)
        else
          uri.query = nil
        end
      end
      
      # Convert to lowercase and remove trailing slash
      normalized = uri.to_s.downcase.chomp("/")
      self.normalized_url = normalized
    rescue URI::InvalidURIError
      # URL format validation will catch this
      self.normalized_url = nil
    end
  end
  
  # Validate URL format - must be a valid HTTP/HTTPS URL
  def submission_url_format
    return if submission_url.blank?
    
    begin
      uri = URI.parse(submission_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:submission_url, "must be a valid URL (e.g., https://example.com)")
      end
    rescue URI::InvalidURIError
      errors.add(:submission_url, "must be a valid URL (e.g., https://example.com)")
    end
  end
  
  # Set default status to pending on creation
  def set_default_status
    self.status ||= :pending
  end
end

