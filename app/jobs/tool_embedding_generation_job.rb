# Job for generating vector embeddings for tools
# Uses RubyLLM.embed to generate embeddings from OpenAI API
# Documentation: https://rubyllm.com/embeddings/
# Embeddings enable semantic search and content similarity matching
class ToolEmbeddingGenerationJob < ApplicationJob
  queue_as :default

  # Retry on transient errors (network issues, rate limits, etc.)
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Discard if tool no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(tool_id)
    generate_embedding(tool_id)
  end

  private

  def generate_embedding(tool_id)
    tool = Tool.find_by(id: tool_id)
    return unless tool

    # Check if embedding column exists (pgvector extension must be installed)
    unless tool.class.column_names.include?("embedding")
      Rails.logger.warn "Embedding column not available for tool #{tool_id}. " \
                       "pgvector extension is not installed. Skipping embedding generation."
      return
    end

    Rails.logger.info "Generating embedding for tool #{tool_id}"

    # Combine text from multiple sources for comprehensive embedding
    text_to_embed = build_embedding_text(tool)

    # Skip if no meaningful text to embed
    if text_to_embed.blank? || text_to_embed.strip.length < 10
      Rails.logger.warn "Tool #{tool_id} has insufficient text for embedding generation"
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
        "UPDATE tools SET embedding = ?::vector WHERE id = ?",
        vector_string,
        tool.id
      ])
    )

    Rails.logger.info "Embedding generated and stored for tool #{tool_id}"
  rescue StandardError => e
    Rails.logger.error "Embedding generation error for tool #{tool_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    # Don't fail the job - embedding generation is not critical for basic functionality
  end

  # Build comprehensive text from tool content for embedding
  # Combines: name, description, and tags
  def build_embedding_text(tool)
    parts = []

    # Add tool name if present
    parts << tool.tool_name if tool.tool_name.present?

    # Add description if present
    parts << tool.tool_description if tool.tool_description.present?

    # Add tags as text
    if tool.tags.any?
      tag_names = tool.tags.pluck(:tag_name).join(", ")
      parts << "Tags: #{tag_names}"
    end

    # Join all parts with newlines for better embedding quality
    parts.join("\n").strip
  end
end
