# Initial schema migration - represents the complete database structure
# This migration replaces all previous migrations and provides a clean starting point
# Fully idempotent - can be run multiple times safely
class CreateInitialSchema < ActiveRecord::Migration[7.1]
  disable_ddl_transaction! # Required for extension operations

  def up
    # Enable PostgreSQL extensions
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    enable_extension "plpgsql" unless extension_enabled?("plpgsql")
    
    # Enable vector extension if available (for pgvector embeddings)
    if extension_available?("vector")
      enable_extension "vector" unless extension_enabled?("vector")
    else
      Rails.logger.warn "pgvector extension not available - embeddings will not be available"
    end

    # Users table (Devise)
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, default: "", null: false
        t.string :encrypted_password, default: "", null: false
        t.string :reset_password_token
        t.datetime :reset_password_sent_at
        t.datetime :remember_created_at
        t.string :username, null: false
        t.integer :user_type, default: 0, null: false
        t.integer :user_status, default: 0, null: false
        t.text :user_bio
        t.timestamps
      end

      add_index :users, :email, unique: true unless index_exists?(:users, :email)
      add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
      add_index :users, :username, unique: true unless index_exists?(:users, :username)
    end

    # Active Storage tables
    unless table_exists?(:active_storage_blobs)
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name, null: false
        t.bigint :byte_size, null: false
        t.string :checksum
        t.datetime :created_at, null: false
      end

      add_index :active_storage_blobs, :key, unique: true unless index_exists?(:active_storage_blobs, :key)
    end

    unless table_exists?(:active_storage_attachments)
      create_table :active_storage_attachments do |t|
        t.string :name, null: false
        t.string :record_type, null: false
        t.bigint :record_id, null: false
        t.bigint :blob_id, null: false
        t.datetime :created_at, null: false
      end

      unless index_exists?(:active_storage_attachments, [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness")
        add_index :active_storage_attachments, [:record_type, :record_id, :name, :blob_id],
                  name: "index_active_storage_attachments_uniqueness", unique: true
      end
      add_index :active_storage_attachments, :blob_id unless index_exists?(:active_storage_attachments, :blob_id)
    end

    unless table_exists?(:active_storage_variant_records)
      create_table :active_storage_variant_records do |t|
        t.bigint :blob_id, null: false
        t.string :variation_digest, null: false
      end

      unless index_exists?(:active_storage_variant_records, [:blob_id, :variation_digest])
        add_index :active_storage_variant_records, [:blob_id, :variation_digest], unique: true
      end
    end

    # Tools table (community-owned, no user_id)
    unless table_exists?(:tools)
      create_table :tools do |t|
        t.string :tool_name, null: false
        t.text :tool_description
        t.string :tool_url
        t.text :author_note
        t.integer :visibility, null: false, default: 0
        t.timestamps
      end

      add_index :tools, :tool_name unless index_exists?(:tools, :tool_name)
    end

    # Add embedding column to tools if vector extension is enabled
    if extension_enabled?("vector") && table_exists?(:tools)
      unless column_exists?(:tools, :embedding)
        execute <<-SQL
          ALTER TABLE tools
          ADD COLUMN embedding vector(1536);
        SQL
      end

      # Add vector index (IVFFlat for cosine similarity search)
      unless index_exists?(:tools, :embedding, name: "index_tools_on_embedding_vector")
        begin
          execute <<-SQL
            CREATE INDEX index_tools_on_embedding_vector
            ON tools
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 1);
          SQL
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.warn "Could not create IVFFlat index for tools: #{e.message}. Index will be created later when data exists."
        end
      end
    end

    # Lists table
    unless table_exists?(:lists)
      create_table :lists do |t|
        t.references :user, null: false, foreign_key: true
        t.string :list_name, null: false
        t.integer :list_type, null: false, default: 0
        t.integer :visibility, null: false, default: 0
        t.timestamps
      end
    end

    # Comments table (polymorphic)
    # Note: t.references automatically creates indexes, so we don't add them again
    unless table_exists?(:comments)
      create_table :comments do |t|
        t.references :user, null: false, foreign_key: true
        t.string :commentable_type, null: false
        t.bigint :commentable_id, null: false
        t.text :comment, null: false
        t.integer :comment_type, null: false, default: 0
        t.integer :visibility, null: false, default: 0
        t.references :parent, foreign_key: { to_table: :comments }, index: true
        t.boolean :solved, null: false, default: false
        t.timestamps
      end

      # Add indexes that aren't automatically created by references
      add_index :comments, [:commentable_type, :commentable_id], name: "index_comments_on_commentable" unless index_exists?(:comments, [:commentable_type, :commentable_id], name: "index_comments_on_commentable")
      # parent_id index is created by t.references above, so we don't add it again
      # user_id index is created by t.references above, so we don't add it again
    end

    # Tags table
    unless table_exists?(:tags)
      create_table :tags do |t|
        t.string :tag_name, null: false
        t.text :tag_description
        t.integer :tag_type, null: false, default: 0
        t.references :parent, foreign_key: { to_table: :tags }, index: true
        t.timestamps
      end

      add_index :tags, :tag_name unless index_exists?(:tags, :tag_name)
      # parent_id index is created by t.references above
    end

    # Tool tags join table
    unless table_exists?(:tool_tags)
      create_table :tool_tags do |t|
        t.references :tool, null: false, foreign_key: true, index: true
        t.references :tag, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:tool_tags, [:tool_id, :tag_id])
        add_index :tool_tags, [:tool_id, :tag_id], unique: true
      end
      # tool_id and tag_id indexes are created by t.references above
    end

    # List tools join table
    unless table_exists?(:list_tools)
      create_table :list_tools do |t|
        t.references :list, null: false, foreign_key: true, index: true
        t.references :tool, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:list_tools, [:list_id, :tool_id])
        add_index :list_tools, [:list_id, :tool_id], unique: true
      end
      # list_id and tool_id indexes are created by t.references above
    end

    # User tools join table (no subscribe column - uses follows instead)
    unless table_exists?(:user_tools)
      create_table :user_tools do |t|
        t.references :user, null: false, foreign_key: true, index: true
        t.references :tool, null: false, foreign_key: true, index: true
        t.datetime :read_at
        t.boolean :upvote, null: false, default: false
        t.boolean :favorite, null: false, default: false
        t.timestamps
      end

      unless index_exists?(:user_tools, [:user_id, :tool_id])
        add_index :user_tools, [:user_id, :tool_id], unique: true
      end
      # user_id and tool_id indexes are created by t.references above
    end

    # Comment upvotes table
    unless table_exists?(:comment_upvotes)
      create_table :comment_upvotes do |t|
        t.references :comment, null: false, foreign_key: true, index: true
        t.references :user, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:comment_upvotes, [:comment_id, :user_id])
        add_index :comment_upvotes, [:comment_id, :user_id], unique: true
      end
      # comment_id and user_id indexes are created by t.references above
    end

    # Follows table (polymorphic - replaces subscribe functionality)
    unless table_exists?(:follows)
      create_table :follows do |t|
        t.references :user, null: false, foreign_key: true, index: true
        t.string :followable_type, null: false
        t.bigint :followable_id, null: false
        t.timestamps
      end

      unless index_exists?(:follows, [:user_id, :followable_type, :followable_id], name: "index_follows_on_user_id_and_followable_type_and_followable_id")
        add_index :follows, [:user_id, :followable_type, :followable_id], unique: true,
                  name: "index_follows_on_user_id_and_followable_type_and_followable_id"
      end
      unless index_exists?(:follows, [:followable_type, :followable_id], name: "index_follows_on_followable")
        add_index :follows, [:followable_type, :followable_id], name: "index_follows_on_followable"
      end
      # user_id index is created by t.references above
    end

    # Submissions table
    unless table_exists?(:submissions)
      create_table :submissions do |t|
        t.references :user, null: false, foreign_key: true, index: true
        t.integer :submission_type, default: 0, null: false
        t.integer :status, default: 0, null: false
        t.string :submission_url
        t.string :normalized_url
        t.text :author_note
        t.string :submission_name
        t.text :submission_description
        t.jsonb :metadata, default: {}, null: false
        t.bigint :duplicate_of_id
        t.datetime :processed_at
        t.timestamps
      end

      # Submissions indexes
      unless index_exists?(:submissions, [:normalized_url, :user_id], name: "index_submissions_on_normalized_url_and_user_id")
        add_index :submissions, [:normalized_url, :user_id], unique: true,
                  where: "normalized_url IS NOT NULL",
                  name: "index_submissions_on_normalized_url_and_user_id"
      end
      add_index :submissions, :status unless index_exists?(:submissions, :status)
      add_index :submissions, :submission_type unless index_exists?(:submissions, :submission_type)
      add_index :submissions, :duplicate_of_id unless index_exists?(:submissions, :duplicate_of_id)
      add_index :submissions, :processed_at unless index_exists?(:submissions, :processed_at)
      unless index_exists?(:submissions, :metadata)
        add_index :submissions, :metadata, using: :gin
      end
      unless index_exists?(:submissions, [:status, :submission_type])
        add_index :submissions, [:status, :submission_type]
      end
      unless index_exists?(:submissions, [:user_id, :status])
        add_index :submissions, [:user_id, :status]
      end
      # user_id index is created by t.references above
    end

    # Add embedding column to submissions if vector extension is enabled
    if extension_enabled?("vector") && table_exists?(:submissions)
      unless column_exists?(:submissions, :embedding)
        execute <<-SQL
          ALTER TABLE submissions
          ADD COLUMN embedding vector(1536);
        SQL
      end

      # Add vector index (IVFFlat for cosine similarity search)
      unless index_exists?(:submissions, :embedding, name: "index_submissions_on_embedding_vector")
        begin
          execute <<-SQL
            CREATE INDEX index_submissions_on_embedding_vector
            ON submissions
            USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 1);
          SQL
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.warn "Could not create IVFFlat index for submissions: #{e.message}. Index will be created later when data exists."
        end
      end
    end

    # Add self-referential foreign key for duplicate_of
    if table_exists?(:submissions) && !foreign_key_exists?(:submissions, :submissions, column: :duplicate_of_id)
      add_foreign_key :submissions, :submissions, column: :duplicate_of_id
    end

    # Submission tags join table
    unless table_exists?(:submission_tags)
      create_table :submission_tags do |t|
        t.references :submission, null: false, foreign_key: true, index: true
        t.references :tag, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:submission_tags, [:submission_id, :tag_id])
        add_index :submission_tags, [:submission_id, :tag_id], unique: true
      end
      # submission_id and tag_id indexes are created by t.references above
    end

    # Submission tools join table
    unless table_exists?(:submission_tools)
      create_table :submission_tools do |t|
        t.references :submission, null: false, foreign_key: true, index: true
        t.references :tool, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:submission_tools, [:submission_id, :tool_id])
        add_index :submission_tools, [:submission_id, :tool_id], unique: true
      end
      # submission_id and tool_id indexes are created by t.references above
    end

    # List submissions join table
    unless table_exists?(:list_submissions)
      create_table :list_submissions do |t|
        t.references :list, null: false, foreign_key: true, index: true
        t.references :submission, null: false, foreign_key: true, index: true
        t.timestamps
      end

      unless index_exists?(:list_submissions, [:list_id, :submission_id])
        add_index :list_submissions, [:list_id, :submission_id], unique: true
      end
      # list_id and submission_id indexes are created by t.references above
    end

    # User submissions join table
    unless table_exists?(:user_submissions)
      create_table :user_submissions do |t|
        t.references :user, null: false, foreign_key: true, index: true
        t.references :submission, null: false, foreign_key: true, index: true
        t.datetime :read_at
        t.boolean :upvote, null: false, default: false
        t.boolean :favorite, null: false, default: false
        t.timestamps
      end

      unless index_exists?(:user_submissions, [:user_id, :submission_id])
        add_index :user_submissions, [:user_id, :submission_id], unique: true
      end
      unless index_exists?(:user_submissions, [:submission_id, :upvote], where: "upvote = true")
        add_index :user_submissions, [:submission_id, :upvote], where: "upvote = true"
      end
      # user_id and submission_id indexes are created by t.references above
    end
  end

  def down
    # Drop tables in reverse order (respecting foreign key dependencies)
    drop_table :user_submissions if table_exists?(:user_submissions)
    drop_table :list_submissions if table_exists?(:list_submissions)
    drop_table :submission_tools if table_exists?(:submission_tools)
    drop_table :submission_tags if table_exists?(:submission_tags)
    drop_table :submissions if table_exists?(:submissions)
    drop_table :follows if table_exists?(:follows)
    drop_table :comment_upvotes if table_exists?(:comment_upvotes)
    drop_table :user_tools if table_exists?(:user_tools)
    drop_table :list_tools if table_exists?(:list_tools)
    drop_table :tool_tags if table_exists?(:tool_tags)
    drop_table :tags if table_exists?(:tags)
    drop_table :comments if table_exists?(:comments)
    drop_table :lists if table_exists?(:lists)
    drop_table :tools if table_exists?(:tools)
    drop_table :active_storage_variant_records if table_exists?(:active_storage_variant_records)
    drop_table :active_storage_attachments if table_exists?(:active_storage_attachments)
    drop_table :active_storage_blobs if table_exists?(:active_storage_blobs)
    drop_table :users if table_exists?(:users)

    # Disable extensions
    disable_extension "vector" if extension_enabled?("vector")
    disable_extension "pg_trgm" if extension_enabled?("pg_trgm")
    # Note: plpgsql is usually required and shouldn't be disabled
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
