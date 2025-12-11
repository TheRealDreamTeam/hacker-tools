class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :followable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:followable_type, :followable_id] }
  validate :cannot_follow_self, if: -> { followable_type == "User" }

  private

  # Prevent users from following themselves
  def cannot_follow_self
    return unless followable_type == "User" && user_id == followable_id

    errors.add(:followable, "cannot be yourself")
  end
end

