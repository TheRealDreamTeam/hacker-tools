# Orchestrator job for processing submissions through the pipeline
# Handles job dependencies, status updates, and error handling
class SubmissionProcessingJob < ApplicationJob
  queue_as :default

  # Retry on transient errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Discard if submission no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(submission_id)
    submission = Submission.find(submission_id)
    
    # Update status to processing
    submission.update!(status: :processing)
    
    # Broadcast status update via Turbo Stream
    broadcast_status_update(submission, :processing)
    
    Rails.logger.info "Starting processing pipeline for submission #{submission_id}"
    
    begin
      # Phase 1: Duplicate check and Safety check (parallel)
      # TODO: Add safety check job in future
      duplicate_result = SubmissionProcessing::DuplicateCheckJob.perform_now(submission_id)
      
      if duplicate_result[:duplicate]
        submission.update!(
          status: :rejected,
          duplicate_of_id: duplicate_result[:duplicate_id]
        )
        broadcast_status_update(submission, :rejected)
        Rails.logger.info "Submission #{submission_id} rejected as duplicate"
        return
      end
      
      # Phase 2: Metadata extraction
      SubmissionProcessing::MetadataExtractionJob.perform_now(submission_id)
      
      # Phase 3: Classification, Tool detection, Tag generation
      SubmissionProcessing::ContentEnrichmentJob.perform_now(submission_id)
      
      # Phase 4: Embedding generation (stub for now)
      # TODO: Implement embedding generation in future
      # SubmissionProcessing::EmbeddingGenerationJob.perform_now(submission_id)
      
      # Phase 5: Relationship discovery (stub for now)
      # TODO: Implement relationship discovery in future
      # SubmissionProcessing::RelationshipDiscoveryJob.perform_now(submission_id)
      
      # Mark as completed
      submission.update!(
        status: :completed,
        processed_at: Time.current
      )
      broadcast_status_update(submission, :completed)
      
      Rails.logger.info "Completed processing pipeline for submission #{submission_id}"
    rescue StandardError => e
      # Mark as failed and log error
      submission.update!(status: :failed)
      submission.set_metadata_value(:error, e.message)
      broadcast_status_update(submission, :failed)
      
      Rails.logger.error "Processing failed for submission #{submission_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Re-raise to trigger retry mechanism
      raise
    end
  end

  private

  # Broadcast status update via Turbo Stream
  def broadcast_status_update(submission, status)
    Turbo::StreamsChannel.broadcast_update_to(
      "submission_#{submission.id}",
      target: "submission-status-#{submission.id}",
      partial: "submissions/status_badge",
      locals: { submission: submission }
    )
  rescue StandardError => e
    # Don't fail the job if broadcast fails
    Rails.logger.warn "Failed to broadcast status update: #{e.message}"
  end
end

