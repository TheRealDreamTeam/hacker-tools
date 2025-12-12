# Join model for many-to-many relationship between Submissions and Tools
# A submission can be about multiple tools (e.g., a submission about pgvector is also about Postgres)
class SubmissionTool < ApplicationRecord
  belongs_to :submission
  belongs_to :tool

  # Prevent duplicate associations
  validates :submission_id, uniqueness: { scope: :tool_id }
end

