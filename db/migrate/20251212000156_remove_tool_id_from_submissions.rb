class RemoveToolIdFromSubmissions < ActiveRecord::Migration[7.1]
  def up
    # Migrate existing tool_id associations to the join table
    # Only migrate if submission_tools table exists (created in previous migration)
    if table_exists?(:submission_tools) && column_exists?(:submissions, :tool_id)
      execute <<-SQL
        INSERT INTO submission_tools (submission_id, tool_id, created_at, updated_at)
        SELECT id, tool_id, created_at, updated_at
        FROM submissions
        WHERE tool_id IS NOT NULL
        ON CONFLICT (submission_id, tool_id) DO NOTHING;
      SQL
    end
    
    # Remove the old tool_id column and foreign key
    remove_reference :submissions, :tool, foreign_key: true if column_exists?(:submissions, :tool_id)
  end

  def down
    # Re-add tool_id column (nullable, since submissions can have multiple tools now)
    add_reference :submissions, :tool, null: true, foreign_key: true
    
    # Migrate first tool from join table back to tool_id (if any tools exist)
    if table_exists?(:submission_tools)
      execute <<-SQL
        UPDATE submissions
        SET tool_id = (
          SELECT tool_id
          FROM submission_tools
          WHERE submission_tools.submission_id = submissions.id
          ORDER BY submission_tools.created_at ASC
          LIMIT 1
        )
        WHERE EXISTS (
          SELECT 1 FROM submission_tools
          WHERE submission_tools.submission_id = submissions.id
        );
      SQL
    end
  end
end
