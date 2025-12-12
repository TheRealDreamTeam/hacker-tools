class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :followable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:followable_type, :followable_id] }
  validate :cannot_follow_self, if: -> { followable_type == "User" }
  validate :cannot_follow_own_list, if: -> { followable_type == "List" }

  private

  # Prevent users from following themselves
  def cannot_follow_self
    return unless followable_type == "User" && user_id == followable_id

    errors.add(:followable, "cannot be yourself")
  end

  # Prevent users from following their own lists
  def cannot_follow_own_list
    return unless followable_type == "List"

    list = followable
    return unless list && user_id == list.user_id

    errors.add(:followable, "cannot be your own list")
  end
end

