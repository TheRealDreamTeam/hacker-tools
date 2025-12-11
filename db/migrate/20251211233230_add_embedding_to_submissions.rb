# Add embedding column for storing vector embeddings (pgvector)
# Embeddings are used for semantic search and content similarity
# Default dimension: 1536 (text-embedding-3-small) or 3072 (text-embedding-3-large)
class AddEmbeddingToSubmissions < ActiveRecord::Migration[7.1]
  def change
    # Add vector column for embeddings
    # Using 1536 dimensions (text-embedding-3-small) as default
    # Can be changed to 3072 for text-embedding-3-large if needed
    add_column :submissions, :embedding, :vector, limit: 1536, null: true

    # Add index for vector similarity search (using cosine distance)
    # This enables fast semantic search queries
    add_index :submissions, :embedding, using: :ivfflat, opclass: :vector_cosine_ops, name: "index_submissions_on_embedding_vector"
  rescue ActiveRecord::StatementInvalid => e
    # If pgvector extension is not available, log warning and skip
    if e.message.include?("vector") || e.message.include?("extension")
      Rails.logger.warn "pgvector extension not available - skipping embedding column. Run migration after installing pgvector."
    else
      raise
    end
  end
end
