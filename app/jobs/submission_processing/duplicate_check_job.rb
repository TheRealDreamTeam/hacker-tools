# Checks if a submission is a duplicate of an existing submission
# Returns hash with :duplicate (boolean) and :duplicate_id (if duplicate)
module SubmissionProcessing
  class DuplicateCheckJob < ApplicationJob
    queue_as :default

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      check_duplicate(submission_id)
    end

    private

    def check_duplicate(submission_id)
      submission = Submission.find(submission_id)
      
      # Skip if no URL (future text-only posts)
      return { duplicate: false } if submission.submission_url.blank?
      
      # Check for exact duplicate (same normalized_url from same user)
      # This is already handled by validation, but check for duplicates from other users
      existing = Submission.where(normalized_url: submission.normalized_url)
                           .where.not(id: submission.id)
                           .where.not(user_id: submission.user_id)
                           .first
      
      if existing
        Rails.logger.info "Found duplicate submission: #{submission.id} duplicates #{existing.id}"
        return { duplicate: true, duplicate_id: existing.id }
      end
      
      # TODO: Implement fuzzy matching for similar URLs
      # For now, only check exact matches
      
      { duplicate: false }
    end
  end
end

