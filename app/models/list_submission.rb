class ListSubmission < ApplicationRecord
  belongs_to :list
  belongs_to :submission
  
  # Prevent duplicate associations
  validates :list_id, uniqueness: { scope: :submission_id }
end

