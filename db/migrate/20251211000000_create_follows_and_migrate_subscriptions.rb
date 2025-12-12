class CreateFollowsAndMigrateSubscriptions < ActiveRecord::Migration[7.1]
  def up
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :followable, polymorphic: true, null: false
      t.timestamps
    end

    add_index :follows, [:user_id, :followable_type, :followable_id], unique: true
    add_index :follows, [:followable_type, :followable_id]

    # Migrate existing tool subscriptions into follows
    migrate_tool_subscriptions

    # Remove legacy subscribe flag from user_tools now that follows are unified
    remove_column :user_tools, :subscribe, :boolean, null: false, default: false
  end

  def down
    # Add subscribe back so we can restore data on rollback
    add_column :user_tools, :subscribe, :boolean, null: false, default: false

    # Restore subscribe flags from follows where followable is Tool
    migrate_follows_back_to_user_tools

    drop_table :follows
  end

  private

  # Local AR classes for migration context
  class Follow < ApplicationRecord
    self.table_name = "follows"
  end

  class UserTool < ApplicationRecord
    self.table_name = "user_tools"
  end

  def migrate_tool_subscriptions
    # Only run if column exists (defensive for re-runs)
    return unless column_exists?(:user_tools, :subscribe)

    say_with_time "Migrating tool subscriptions to follows" do
      UserTool.where(subscribe: true).find_each do |user_tool|
        Follow.find_or_create_by!(
          user_id: user_tool.user_id,
          followable_type: "Tool",
          followable_id: user_tool.tool_id
        )
      end
    end
  end

  def migrate_follows_back_to_user_tools
    say_with_time "Migrating tool follows back to user_tools.subscribe" do
      Follow.where(followable_type: "Tool").find_each do |follow|
        # Avoid creating duplicates; ensure row exists
        ut = UserTool.find_or_create_by!(user_id: follow.user_id, tool_id: follow.followable_id)
        ut.update!(subscribe: true)
      end
    end
  end
end

