# Enriches submission with classification, tool detection, and tag generation using RubyLLM
module SubmissionProcessing
  class ContentEnrichmentJob < ApplicationJob
    queue_as :default

    # Public method that can be called directly (for orchestrator)
    def perform(submission_id)
      enrich_content(submission_id)
    end

    private

    def enrich_content(submission_id)
      submission = Submission.find(submission_id)
      
      Rails.logger.info "Starting content enrichment for submission #{submission_id}"
      
      # TODO: Implement RubyLLM-based classification, tool detection, and tag generation
      # For now, this is a stub that will be implemented in Step 2.3
      
      # Placeholder: Set basic classification based on URL patterns
      classify_submission_type(submission)
      
      # Placeholder: Basic tool detection (stub)
      # detect_tool(submission)
      
      # Placeholder: Basic tag generation (stub)
      # generate_tags(submission)
      
      Rails.logger.info "Content enrichment completed for submission #{submission_id}"
    end

    private

    # Basic classification based on URL patterns
    def classify_submission_type(submission)
      return if submission.submission_url.blank?
      
      url = submission.submission_url.downcase
      
      if url.include?("github.com")
        submission.update!(submission_type: :github_repo) unless submission.github_repo?
      elsif url.include?("docs.") || url.include?("/docs/") || url.include?("documentation")
        submission.update!(submission_type: :documentation) unless submission.documentation?
      elsif url.include?("guide") || url.include?("tutorial")
        submission.update!(submission_type: :guide) unless submission.guide?
      else
        # Default to article
        submission.update!(submission_type: :article) unless submission.article?
      end
    end
  end
end

