class UserTool < ApplicationRecord
  belongs_to :user
  belongs_to :tool

  validates :user_id, uniqueness: { scope: :tool_id }
end

