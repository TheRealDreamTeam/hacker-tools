class FixNormalizedUrlIndexScope < ActiveRecord::Migration[7.1]
  def change
    # Remove the global unique index on normalized_url
    remove_index :submissions, :normalized_url, if_exists: true
    
    # Add a composite unique index scoped to user_id (matches the validation)
    add_index :submissions, [:normalized_url, :user_id], 
              unique: true, 
              where: "normalized_url IS NOT NULL",
              name: "index_submissions_on_normalized_url_and_user_id"
  end
end

