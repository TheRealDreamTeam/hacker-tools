class UpdateTagsTableStructure < ActiveRecord::Migration[7.1]
  def up
    # Change tag_name from string to text (PostgreSQL treats them similarly, but for consistency)
    change_column :tags, :tag_name, :text, null: false

    # Add new columns
    add_column :tags, :tag_slug, :text
    add_column :tags, :tag_type_id, :integer
    add_column :tags, :tag_type_slug, :text
    add_column :tags, :color, :text
    add_column :tags, :icon, :text
    add_column :tags, :tag_alias, :text

    # Migrate tag_type from integer enum to text
    # First, add a temporary text column
    add_column :tags, :tag_type_text, :text

    # Map existing enum integer values to text
    # enum tag_type: { category: 0, language: 1, framework: 2, library: 3, version: 4, platform: 5, other: 6 }
    execute <<-SQL
      UPDATE tags SET tag_type_text = CASE tag_type
        WHEN 0 THEN 'category'
        WHEN 1 THEN 'language'
        WHEN 2 THEN 'framework'
        WHEN 3 THEN 'library'
        WHEN 4 THEN 'version'
        WHEN 5 THEN 'platform'
        WHEN 6 THEN 'other'
        ELSE 'other'
      END
    SQL

    # Remove the old integer column
    remove_column :tags, :tag_type

    # Rename the text column to tag_type
    rename_column :tags, :tag_type_text, :tag_type

    # Set tag_type as NOT NULL (since it was required before)
    change_column_null :tags, :tag_type, false

    # Populate tag_type_id based on tag_type text values
    # This maps the text tag_type to an integer tag_type_id
    execute <<-SQL
      UPDATE tags SET tag_type_id = CASE tag_type
        WHEN 'category' THEN 0
        WHEN 'language' THEN 1
        WHEN 'framework' THEN 2
        WHEN 'library' THEN 3
        WHEN 'version' THEN 4
        WHEN 'platform' THEN 5
        WHEN 'other' THEN 6
        ELSE 6
      END
    SQL
  end

  def down
    # Revert tag_type from text back to integer enum
    add_column :tags, :tag_type_int, :integer, null: false, default: 0

    # Map text values back to integer enum
    execute <<-SQL
      UPDATE tags SET tag_type_int = CASE tag_type
        WHEN 'category' THEN 0
        WHEN 'language' THEN 1
        WHEN 'framework' THEN 2
        WHEN 'library' THEN 3
        WHEN 'version' THEN 4
        WHEN 'platform' THEN 5
        WHEN 'other' THEN 6
        ELSE 6
      END
    SQL

    remove_column :tags, :tag_type
    rename_column :tags, :tag_type_int, :tag_type

    # Remove new columns
    remove_column :tags, :tag_alias
    remove_column :tags, :icon
    remove_column :tags, :color
    remove_column :tags, :tag_type_slug
    remove_column :tags, :tag_type_id
    remove_column :tags, :tag_slug

    # Revert tag_name back to string
    change_column :tags, :tag_name, :string, null: false
  end
end
