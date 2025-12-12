class UserSubmission < ApplicationRecord
  belongs_to :user
  belongs_to :submission

  validates :user_id, uniqueness: { scope: :submission_id }
end
