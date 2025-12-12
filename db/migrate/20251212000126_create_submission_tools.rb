class CreateSubmissionTools < ActiveRecord::Migration[7.1]
  def change
    create_table :submission_tools do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: true

      t.timestamps
    end
    
    # Unique index to prevent duplicate tool associations
    add_index :submission_tools, [:submission_id, :tool_id], unique: true
  end
end
