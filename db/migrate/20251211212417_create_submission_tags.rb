class CreateSubmissionTags < ActiveRecord::Migration[7.1]
  def change
    create_table :submission_tags do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    
    # Unique index to prevent duplicate tag associations
    add_index :submission_tags, [:submission_id, :tag_id], unique: true
  end
end
