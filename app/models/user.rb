class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # User status enum: active (0) or deleted (1)
  # Using explicit scopes instead of default_scope to allow associations to work correctly
  # (e.g., comment.user should return user even if deleted)
  enum user_status: { active: 0, deleted: 1 }

  # Explicit scopes for filtering users by status
  # Note: No default_scope - we want associations to work with deleted users
  scope :active, -> { where(user_status: :active) }
  scope :deleted, -> { where(user_status: :deleted) }

  # Active Storage avatar to avoid storing URLs directly and allow variants.
  has_one_attached :avatar

  # Associations
  has_many :tools, dependent: :destroy
  has_many :lists, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :user_tools, dependent: :destroy
  has_many :comment_upvotes, dependent: :destroy
  has_many :follows, dependent: :destroy

  # Through associations for interactions
  has_many :upvoted_tools, -> { where(user_tools: { upvote: true }) }, through: :user_tools, source: :tool
  has_many :favorited_tools, -> { where(user_tools: { favorite: true }) }, through: :user_tools, source: :tool

  # Polymorphic follows
  has_many :followed_tools, -> { where(follows: { followable_type: "Tool" }) }, through: :follows, source: :followable, source_type: "Tool"
  has_many :followed_lists, -> { where(follows: { followable_type: "List" }) }, through: :follows, source: :followable, source_type: "List"
  has_many :followed_tags,  -> { where(follows: { followable_type: "Tag" }) }, through: :follows, source: :followable, source_type: "Tag"
  has_many :followed_users, -> { where(follows: { followable_type: "User" }) }, through: :follows, source: :followable, source_type: "User"

  # Followers (for this user as followable)
  has_many :follower_follows, as: :followable, class_name: "Follow", dependent: :destroy
  has_many :followers, through: :follower_follows, source: :user

  # Username validation: must be unique among active users only
  # This allows username reuse after account deletion
  validates :username, presence: true
  validate :username_uniqueness_for_active_users

  # Email validation: Devise handles uniqueness, but we need to allow reuse for deleted users
  # Devise's uniqueness validation will be overridden to exclude deleted users
  validate :email_uniqueness_for_active_users

  # Override Devise's active_for_authentication? to prevent deleted users from logging in
  def active_for_authentication?
    super && !deleted?
  end

  # Custom Devise message for deleted accounts
  def inactive_message
    deleted? ? :deleted : super
  end

  # Helper methods
  def upvoted_tools_count
    user_tools.where(upvote: true).count
  end

  def favorite_count
    user_tools.where(favorite: true).count
  end

  # Follow helpers
  def follows?(followable)
    follows.exists?(followable:)
  end

  # Check if user is deleted
  def deleted?
    user_status == "deleted"
  end

  # Soft delete: mark user as deleted and anonymize username/email
  # This frees up username/email for reuse while preserving historical data
  def soft_delete!
    transaction do
      # Anonymize username and email to free them up for reuse
      # Using unique identifiers ensures no conflicts
      update!(
        user_status: :deleted,
        username: "deleted_user_#{id}",
        email: "deleted_#{id}@deleted.local",
        # Clear sensitive authentication tokens
        reset_password_token: nil,
        reset_password_sent_at: nil,
        remember_created_at: nil
      )
    end
  end

  private

  # Custom username uniqueness validation that excludes deleted users
  # This allows username reuse after account deletion
  def username_uniqueness_for_active_users
    return if deleted? # Skip validation for deleted users (they have anonymized usernames)

    # Check if username is already taken by an active user
    existing_user = User.active.find_by(username: username)
    if existing_user && existing_user != self
      errors.add(:username, :taken)
    end
  end

  # Custom email uniqueness validation that excludes deleted users
  # This allows email reuse after account deletion
  def email_uniqueness_for_active_users
    return if deleted? # Skip validation for deleted users (they have anonymized emails)

    # Check if email is already taken by an active user
    existing_user = User.active.find_by(email: email)
    if existing_user && existing_user != self
      errors.add(:email, :taken)
    end
  end
end
