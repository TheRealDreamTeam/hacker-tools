class Comment < ApplicationRecord
  belongs_to :tool
  belongs_to :user

  # Self-referential parent-child relationship for threaded comments
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  # Upvotes on comments
  has_many :comment_upvotes, dependent: :destroy
  has_many :upvoters, through: :comment_upvotes, source: :user

  validates :comment, presence: true

  # Scopes
  scope :top_level, -> { where(parent_id: nil) }
  scope :replies, -> { where.not(parent_id: nil) }
  scope :solved, -> { where(solved: true) }
  scope :unsolved, -> { where(solved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_upvoted, -> { joins(:comment_upvotes).group("comments.id").order("COUNT(comment_upvotes.id) DESC") }
end

