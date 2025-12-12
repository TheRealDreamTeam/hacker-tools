class MakeCommentsPolymorphic < ActiveRecord::Migration[7.1]
  def change
    # Remove old tool_id foreign key and column
    remove_foreign_key :comments, :tools
    remove_index :comments, :tool_id if index_exists?(:comments, :tool_id)
    
    # Add polymorphic columns
    add_reference :comments, :commentable, polymorphic: true, null: false, index: true
    
    # Remove old tool_id column
    remove_column :comments, :tool_id, :bigint
  end
end
