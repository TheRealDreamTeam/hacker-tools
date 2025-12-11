class CreateSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :submissions do |t|
      # User ownership - submissions belong to users
      t.references :user, null: false, foreign_key: true
      
      # Tool association - submissions can be about tools (optional)
      t.references :tool, null: true, foreign_key: true
      
      # Submission type enum (article, guide, documentation, github_repo, etc.)
      t.integer :submission_type, default: 0, null: false
      
      # Status enum (pending, processing, completed, failed, rejected)
      t.integer :status, default: 0, null: false
      
      # URL and normalized URL for duplicate detection
      t.string :submission_url, null: true # Nullable for future text-only posts
      t.string :normalized_url, null: true # Nullable for future text-only posts
      
      # Content fields
      t.text :author_note # Free text description from user
      t.string :submission_name # Extracted/derived name
      t.text :submission_description # Extracted description
      
      # Metadata storage (JSONB for flexible data)
      t.jsonb :metadata, default: {}, null: false
      
      # Duplicate detection (self-referential, foreign key added after table creation)
      t.bigint :duplicate_of_id, null: true
      
      # Processing tracking
      t.datetime :processed_at, null: true
      
      # Embedding for semantic search (vector type - will be added in Step 2.2)
      # Note: We'll add the embedding column in a separate migration after enabling pgvector
      
      t.timestamps
    end
    
    # Indexes for performance
    # Note: user_id and tool_id indexes are created automatically by t.references above
    add_index :submissions, :normalized_url, unique: true, where: "normalized_url IS NOT NULL"
    add_index :submissions, :status
    add_index :submissions, :submission_type
    add_index :submissions, :duplicate_of_id
    add_index :submissions, :processed_at
    
    # GIN index on metadata for JSONB queries
    add_index :submissions, :metadata, using: :gin
    
    # Composite indexes for common query patterns
    add_index :submissions, [:status, :submission_type]
    add_index :submissions, [:user_id, :status]
    
    # Add self-referential foreign key for duplicate_of after table is created
    add_foreign_key :submissions, :submissions, column: :duplicate_of_id
  end
end
