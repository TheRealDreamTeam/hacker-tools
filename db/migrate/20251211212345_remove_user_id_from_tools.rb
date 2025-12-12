class RemoveUserIdFromTools < ActiveRecord::Migration[7.1]
  def change
    # Remove user_id from tools - tools are now community-owned, not user-owned
    # Users submit content (submissions) about tools, but don't own the tools themselves
    
    # Remove foreign key if it exists
    if foreign_key_exists?(:tools, :users)
      remove_foreign_key :tools, :users
    end
    
    # Remove the user_id column and its index
    if column_exists?(:tools, :user_id)
      remove_index :tools, :user_id if index_exists?(:tools, :user_id)
      remove_column :tools, :user_id, :bigint
    end
  end
end
