# Job for generating vector embeddings for submissions
# Uses RubyLLM.embed to generate embeddings from OpenAI API
# Documentation: https://rubyllm.com/embeddings/
# Embeddings enable semantic search and content similarity matching
module SubmissionProcessing
  class EmbeddingGenerationJob < ApplicationJob
    queue_as :default

    # Retry on transient errors (network issues, rate limits, etc.)
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Discard if submission no longer exists
    discard_on ActiveRecord::RecordNotFound

    def perform(submission_id)
      generate_embedding(submission_id)
    end

    private

    def generate_embedding(submission_id)
      submission = Submission.find_by(id: submission_id)
      return unless submission

      # Check if embedding column exists (pgvector extension must be installed)
      unless submission.class.column_names.include?("embedding")
        Rails.logger.warn "Embedding column not available for submission #{submission_id}. " \
                         "pgvector extension is not installed. Skipping embedding generation."
        return
      end

      Rails.logger.info "Generating embedding for submission #{submission_id}"

      # Combine text from multiple sources for comprehensive embedding
      text_to_embed = build_embedding_text(submission)

      # Skip if no meaningful text to embed
      if text_to_embed.blank? || text_to_embed.strip.length < 10
        Rails.logger.warn "Submission #{submission_id} has insufficient text for embedding generation"
        return
      end

      # Generate embedding using RubyLLM
      # Use text-embedding-3-small (1536 dimensions) by default
      # Can be changed to text-embedding-3-large (3072 dimensions) if needed
      embedding_result = RubyLLM.embed(text_to_embed, model: "text-embedding-3-small")

      # Extract the vector array from RubyLLM::Embedding object
      # RubyLLM.embed returns a RubyLLM::Embedding object with a vectors method
      # pgvector expects an array of floats
      embedding_array = embedding_result.vectors

      # Ensure all values are floats (pgvector requires numeric array)
      embedding_array = embedding_array.map(&:to_f)

      # Store embedding using raw SQL with proper vector casting
      # Active Record doesn't automatically cast arrays to vector type
      # Format: '[0.1,0.2,0.3]'::vector
      # Use parameterized query to prevent SQL injection
      vector_string = "[#{embedding_array.join(',')}]"
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
          "UPDATE submissions SET embedding = ?::vector WHERE id = ?",
          vector_string,
          submission.id
        ])
      )

      Rails.logger.info "Embedding generated and stored for submission #{submission_id}"
    rescue StandardError => e
      Rails.logger.error "Embedding generation error for submission #{submission_id}: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      # Don't fail the job - embedding generation is not critical for basic functionality
    end

    # Build comprehensive text from submission content for embedding
    # Combines: title, description, tags, and extracted content
    # Note: author_note is excluded as it's user commentary, not content
    def build_embedding_text(submission)
      parts = []

      # Add title if present
      parts << submission.submission_name if submission.submission_name.present?

      # Add description if present
      parts << submission.submission_description if submission.submission_description.present?

      # Add tags as text
      if submission.tags.any?
        tag_names = submission.tags.pluck(:tag_name).join(", ")
        parts << "Tags: #{tag_names}"
      end

      # Add extracted content from metadata if available
      if submission.metadata.present?
        extracted_content = submission.metadata["extracted_description"] || submission.metadata["extracted_title"]
        parts << extracted_content if extracted_content.present?
      end

      # Join all parts with newlines for better embedding quality
      parts.join("\n").strip
    end
  end
end

