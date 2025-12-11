class SubmissionTag < ApplicationRecord
  belongs_to :submission
  belongs_to :tag
  
  # Prevent duplicate tag associations
  validates :submission_id, uniqueness: { scope: :tag_id }
end

