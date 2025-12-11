class EnablePostgresExtensions < ActiveRecord::Migration[7.1]
  def change
    # Enable pg_trgm extension for trigram search (fuzzy text matching)
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    
    # Enable vector extension for pgvector (embeddings/semantic search)
    # Note: This requires pgvector to be installed on the PostgreSQL server
    # For now, we'll enable it conditionally - it will be added when pgvector is installed
    begin
      enable_extension "vector" unless extension_enabled?("vector")
    rescue ActiveRecord::StatementInvalid => e
      # If vector extension is not available, log warning and continue
      Rails.logger.warn "pgvector extension not available: #{e.message}"
      # Migration will continue without vector extension
      # Embeddings will be added in a future migration when pgvector is installed
    end
  end
end
