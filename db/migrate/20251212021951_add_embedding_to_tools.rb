# Add embedding column for storing vector embeddings (pgvector)
# Embeddings are used for semantic search and content similarity
# Default dimension: 1536 (text-embedding-3-small) or 3072 (text-embedding-3-large)
class AddEmbeddingToTools < ActiveRecord::Migration[7.1]
  disable_ddl_transaction! # Allow individual statements to commit even if others fail

  def up
    # Try to enable vector extension if available but not enabled
    if extension_available?("vector") && !extension_enabled?("vector")
      enable_extension "vector"
    end

    # Check if vector extension is enabled before adding column
    unless extension_enabled?("vector")
      Rails.logger.warn "pgvector extension not enabled - skipping embedding column. Enable pgvector extension first."
      return
    end

    # Add vector column for embeddings using raw SQL
    # Using 1536 dimensions (text-embedding-3-small) as default
    # Can be changed to 3072 for text-embedding-3-large if needed
    execute <<-SQL
      ALTER TABLE tools
      ADD COLUMN embedding vector(1536);
    SQL

    # Add index for vector similarity search (using cosine distance)
    # Note: IVFFlat index requires data to exist and works best with 1000+ rows
    # We'll create a basic index now - can be upgraded to IVFFlat later when we have more data
    # For now, use a simple index that works with any amount of data
    begin
      execute <<-SQL
        CREATE INDEX index_tools_on_embedding_vector
        ON tools
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 10);
      SQL
    rescue ActiveRecord::StatementInvalid => e
      # If IVFFlat index creation fails (e.g., no data yet), try with minimal lists
      if e.message.include?("ivfflat") || e.message.include?("lists")
        Rails.logger.info "Creating basic vector index with minimal lists (IVFFlat requires data - will upgrade later)"
        begin
          execute <<-SQL
            CREATE INDEX index_tools_on_embedding_vector
            ON tools
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 1);
          SQL
        rescue ActiveRecord::StatementInvalid => e2
          # If even minimal lists fails, skip index creation for now
          Rails.logger.warn "Could not create IVFFlat index: #{e2.message}. Index will be created later when data exists."
        end
      else
        raise
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    # If pgvector extension is not available, log warning and skip
    if e.message.include?("vector") || e.message.include?("extension") || e.message.include?("does not exist")
      Rails.logger.warn "pgvector extension not available - skipping embedding column. Run migration after installing pgvector."
    else
      raise
    end
  end

  private

  # Check if an extension is available on the PostgreSQL server
  def extension_available?(extension_name)
    connection.execute(
      "SELECT EXISTS(SELECT 1 FROM pg_available_extensions WHERE name = '#{extension_name}')"
    ).first["exists"]
  rescue StandardError
    false
  end

  def down
    remove_index :tools, name: "index_tools_on_embedding_vector" if index_exists?(:tools, :embedding, name: "index_tools_on_embedding_vector")
    remove_column :tools, :embedding if column_exists?(:tools, :embedding)
  end
end
