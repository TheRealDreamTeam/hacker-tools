class Comment < ApplicationRecord
  # Polymorphic association - comments can belong to Tools or Submissions
  belongs_to :commentable, polymorphic: true
  belongs_to :user

  # Self-referential parent-child relationship for threaded comments
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  # Upvotes on comments
  has_many :comment_upvotes, dependent: :destroy
  has_many :upvoters, through: :comment_upvotes, source: :user

  enum comment_type: { comment: 0, flag: 1, bug: 2 }, _prefix: true

  before_validation :default_comment_type

  validates :comment, presence: true
  validates :comment_type, presence: true

  # Scopes
  scope :top_level, -> { where(parent_id: nil) }
  scope :replies, -> { where.not(parent_id: nil) }
  scope :solved, -> { where(solved: true) }
  scope :unsolved, -> { where(solved: false) }
  scope :recent, -> { order(created_at: :desc) }
  # Most upvoted includes comments with 0 upvotes (left join)
  scope :most_upvoted, -> { left_joins(:comment_upvotes).group("comments.id").order("COUNT(comment_upvotes.id) DESC, comments.created_at DESC") }
  # Trending: most upvoted in last 7 days
  scope :trending, -> { where("comments.created_at >= ?", 7.days.ago).left_joins(:comment_upvotes).group("comments.id").order("COUNT(comment_upvotes.id) DESC, comments.created_at DESC") }

  # Check if current user has upvoted this comment
  def upvoted_by?(user)
    return false unless user

    comment_upvotes.exists?(user: user)
  end

  # Get upvote count
  def upvote_count
    comment_upvotes.count
  end
  
  # Helper method to get the tool (for backward compatibility during migration)
  # This will work for both Tool and Submission commentables
  def tool
    commentable.is_a?(Tool) ? commentable : commentable&.tool
  end

  private

  def default_comment_type
    self.comment_type ||= :comment
  end
end

