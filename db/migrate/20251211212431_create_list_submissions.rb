class CreateListSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :list_submissions do |t|
      t.references :list, null: false, foreign_key: true
      t.references :submission, null: false, foreign_key: true

      t.timestamps
    end
    
    # Unique index to prevent duplicate associations
    add_index :list_submissions, [:list_id, :submission_id], unique: true
  end
end
