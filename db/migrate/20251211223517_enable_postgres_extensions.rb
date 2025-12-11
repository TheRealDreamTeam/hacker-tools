class EnablePostgresExtensions < ActiveRecord::Migration[7.1]
  # Disable DDL transaction for extension operations
  # Extensions may not be available and we want to handle that gracefully
  disable_ddl_transaction!

  def up
    # Enable pg_trgm extension for trigram search (fuzzy text matching)
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    
    # Enable vector extension for pgvector (embeddings/semantic search)
    # Note: This requires pgvector to be installed on the PostgreSQL server
    # Check if extension is available before trying to enable it
    if extension_available?("vector")
      enable_extension "vector" unless extension_enabled?("vector")
    else
      Rails.logger.warn "pgvector extension not available - skipping. Embeddings will be added in a future migration."
    end
  end

  def down
    disable_extension "vector" if extension_enabled?("vector")
    disable_extension "pg_trgm" if extension_enabled?("pg_trgm")
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
end
