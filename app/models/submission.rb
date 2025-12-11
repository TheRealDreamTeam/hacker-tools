class Submission < ApplicationRecord
  # User ownership - submissions belong to users
  belongs_to :user
  
  # Tool association - submissions can be about tools (optional)
  belongs_to :tool, optional: true
  
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
  
  # Scopes
  scope :pending, -> { where(status: statuses[:pending]) }
  scope :processing, -> { where(status: statuses[:processing]) }
  scope :completed, -> { where(status: statuses[:completed]) }
  scope :failed, -> { where(status: statuses[:failed]) }
  scope :rejected, -> { where(status: statuses[:rejected]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(submission_type: submission_types[type]) }
  scope :for_tool, ->(tool) { where(tool: tool) }
  
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
  # Removes trailing slashes, query params, fragments, www prefix, converts to lowercase
  def normalize_url
    return if submission_url.blank?
    
    begin
      uri = URI.parse(submission_url)
      # Only normalize HTTP/HTTPS URLs
      return unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      
      # Remove www prefix from host
      uri.host = uri.host&.sub(/\Awww\./, "")
      # Remove fragment
      uri.fragment = nil
      # Remove query params (or keep specific ones if needed)
      uri.query = nil
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

