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
  after_create_commit :notify_comment_created
  after_update_commit :notify_comment_resolved, if: :saved_change_to_solved?

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
  
  # Notify relevant users when a comment is created
  def notify_comment_created
    return if user.deleted? # Skip notifications for deleted users
    
    if parent_id.present?
      # This is a reply - notify the parent comment author
      # Note: We don't skip if submission owner replies - they should still notify the parent comment author
      # Reload parent to ensure it's loaded from database
      parent_comment = Comment.find_by(id: parent_id)
      if parent_comment
        parent_author = parent_comment.user
        Rails.logger.info "Reply notification: Comment #{id} is a reply to comment #{parent_id} by user #{parent_author&.id}"
        if parent_author && parent_author != user && !parent_author.deleted?
          Rails.logger.info "Sending reply notification to user #{parent_author.id}"
          ReplyToCommentNotifier.with(
            record: self,
            comment: self,
            commentable: commentable,
            user: user,
            parent: parent_comment
          ).deliver_later(parent_author)
        else
          Rails.logger.warn "Skipping reply notification: parent_author=#{parent_author&.id}, current_user=#{user.id}, deleted=#{parent_author&.deleted?}"
        end
      else
        Rails.logger.error "Parent comment #{parent_id} not found for reply comment #{id}"
      end
    else
      # This is a top-level comment - notify the submission/tool owner
      # Don't notify about own top-level comments
      return if commentable.is_a?(Submission) && commentable.user == user
      return if commentable.is_a?(Tool) && user == user # Tools are community-owned
      
      if commentable.is_a?(Submission)
        submission_owner = commentable.user
        if submission_owner && submission_owner != user && !submission_owner.deleted?
          NewTopLevelCommentNotifier.with(
            record: self,
            comment: self,
            commentable: commentable,
            user: user
          ).deliver_later(submission_owner)
        end
      elsif commentable.is_a?(Tool)
        # For tools, notify users who previously commented (to keep them engaged)
        # This is a simplified version - could be enhanced to notify all previous commenters
        # For now, we'll skip tool comment notifications to avoid spam
        # TODO: Implement opt-in notification preferences for tool comment threads
      end
    end
  end
  
  # Notify users when a flag or bug is resolved
  def notify_comment_resolved
    return unless solved? # Only notify when resolved (not when unresolved)
    return unless comment_type_flag? || comment_type_bug?
    
    recipients = []
    
    # Notify the flag/bug creator
    recipients << user unless user.deleted?
    
    # Notify users who upvoted the flag/bug
    upvoters.each { |upvoter| recipients << upvoter unless upvoter.deleted? }
    
    # Notify submission/tool owner if applicable
    if commentable.is_a?(Submission)
      recipients << commentable.user unless commentable.user.deleted?
    end
    
    # Remove duplicates and the resolver (if they're in the list)
    recipients = recipients.uniq
    
    return if recipients.empty?
    
    notifier_class = comment_type_flag? ? FlagResolvedNotifier : BugResolvedNotifier
    
    notifier_class.with(
      record: self,
      flag: self,
      bug: self, # Both params for flexibility
      commentable: commentable
    ).deliver_later(recipients)
  end
end

