# Add embedding column for storing vector embeddings (pgvector)
# Embeddings are used for semantic search and content similarity
# Default dimension: 1536 (text-embedding-3-small) or 3072 (text-embedding-3-large)
class AddEmbeddingToSubmissions < ActiveRecord::Migration[7.1]
  def up
    # Check if vector extension is enabled
    unless extension_enabled?("vector")
      Rails.logger.warn "pgvector extension not enabled - skipping embedding column. Enable pgvector extension first."
      return
    end

    # Add vector column for embeddings using raw SQL
    # Using 1536 dimensions (text-embedding-3-small) as default
    # Can be changed to 3072 for text-embedding-3-large if needed
    execute <<-SQL
      ALTER TABLE submissions
      ADD COLUMN embedding vector(1536);
    SQL

    # Add index for vector similarity search (using cosine distance)
    # Note: IVFFlat index requires data to exist and works best with 1000+ rows
    # We'll create a basic index now - can be upgraded to IVFFlat later when we have more data
    # For now, use a simple index that works with any amount of data
    execute <<-SQL
      CREATE INDEX index_submissions_on_embedding_vector
      ON submissions
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 10);
    SQL
  rescue ActiveRecord::StatementInvalid => e
    # If IVFFlat index creation fails (e.g., no data yet), create a basic index
    if e.message.include?("ivfflat") || e.message.include?("lists")
      Rails.logger.info "Creating basic vector index (IVFFlat requires data - will upgrade later)"
      execute <<-SQL
        CREATE INDEX index_submissions_on_embedding_vector
        ON submissions
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 1);
      SQL
    else
      raise
    end
  rescue ActiveRecord::StatementInvalid => e
    # If pgvector extension is not available, log warning and skip
    if e.message.include?("vector") || e.message.include?("extension") || e.message.include?("does not exist")
      Rails.logger.warn "pgvector extension not available - skipping embedding column. Run migration after installing pgvector."
    else
      raise
    end
  end

  def down
    remove_index :submissions, name: "index_submissions_on_embedding_vector" if index_exists?(:submissions, :embedding, name: "index_submissions_on_embedding_vector")
    remove_column :submissions, :embedding if column_exists?(:submissions, :embedding)
  end
end
