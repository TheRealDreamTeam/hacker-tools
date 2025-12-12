class CreateUserSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :submission, null: false, foreign_key: true
      t.datetime :read_at
      t.boolean :upvote, default: false, null: false
      t.boolean :favorite, default: false, null: false

      t.timestamps
    end
    
    # Add unique index to prevent duplicate user-submission pairs
    add_index :user_submissions, [:user_id, :submission_id], unique: true
    # Add index for efficient upvote queries
    add_index :user_submissions, [:submission_id, :upvote], where: "upvote = true"
  end
end
