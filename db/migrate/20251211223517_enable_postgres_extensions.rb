class EnablePostgresExtensions < ActiveRecord::Migration[7.1]
  def change
    # Enable pg_trgm extension for trigram search (fuzzy text matching)
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    
    # Enable vector extension for pgvector (embeddings/semantic search)
    enable_extension "vector" unless extension_enabled?("vector")
  end
end
