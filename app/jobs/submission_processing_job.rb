# Orchestrator job for processing submissions through the pipeline
# Handles job dependencies, status updates, and error handling
class SubmissionProcessingJob < ApplicationJob
  queue_as :default

  # Retry on transient errors
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

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
      broadcast_phase_update(submission, "validating", "Validating submission...")
      
      duplicate_check = SubmissionProcessing::DuplicateCheckJob.new
      duplicate_result = duplicate_check.perform(submission_id)
      
      if duplicate_result[:duplicate]
        submission.update!(
          status: :rejected,
          duplicate_of_id: duplicate_result[:duplicate_id]
        )
        broadcast_status_update(submission, :rejected, "This URL has already been submitted.")
        Rails.logger.info "Submission #{submission_id} rejected as duplicate"
        return
      end
      
      # Run safety check
      safety_check = SubmissionProcessing::SafetyCheckJob.new
      safety_result = safety_check.perform(submission_id)
      
      unless safety_result[:safe]
        submission.update!(
          status: :rejected,
          metadata: submission.metadata.merge(rejection_reason: safety_result[:reason])
        )
        broadcast_status_update(submission, :rejected, safety_result[:reason] || "Content validation failed")
        Rails.logger.info "Submission #{submission_id} rejected: #{safety_result[:reason]}"
        return
      end
      
      # Phase 2: Metadata extraction
      broadcast_phase_update(submission, "extracting", "Extracting metadata...")
      SubmissionProcessing::MetadataExtractionJob.perform_now(submission_id)
      
      # Phase 3: Classification, Tool detection, Tag generation
      broadcast_phase_update(submission, "enriching", "Enriching content...")
      SubmissionProcessing::ContentEnrichmentJob.perform_now(submission_id)
      
      # Phase 4: Embedding generation
      broadcast_phase_update(submission, "generating_embedding", "Generating embedding...")
      SubmissionProcessing::EmbeddingGenerationJob.perform_now(submission_id)
      
      # Phase 5: Relationship discovery (stub - Phase 2)
      SubmissionProcessing::RelationshipDiscoveryJob.perform_now(submission_id)
      
      # Mark as completed
      submission.update!(
        status: :completed,
        processed_at: Time.current
      )
      broadcast_status_update(submission, :completed, "Processing complete!")
      
      # Note: Redirect is handled by the controller after form submission
      # The user is already on the submission show page, so no redirect needed
      # Processing status updates are broadcast via Turbo Streams
      
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
  def broadcast_status_update(submission, status, message = nil)
    Turbo::StreamsChannel.broadcast_update_to(
      "submission_#{submission.id}",
      target: "submission-processing-status-container",
      partial: "submissions/processing_status",
      locals: { 
        submission: submission, 
        status: status,
        message: message
      }
    )
  rescue StandardError => e
    # Don't fail the job if broadcast fails
    Rails.logger.warn "Failed to broadcast status update: #{e.message}"
  end

  # Broadcast phase update (for intermediate steps)
  def broadcast_phase_update(submission, phase, message)
    Turbo::StreamsChannel.broadcast_update_to(
      "submission_#{submission.id}",
      target: "submission-processing-status-container",
      partial: "submissions/processing_status",
      locals: { 
        submission: submission, 
        status: :processing,
        phase: phase,
        message: message
      }
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to broadcast phase update: #{e.message}"
  end
end

