class CreateToolingSchema < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string  :username, null: false
      t.integer :user_type, null: false, default: 0
      t.integer :user_status, null: false, default: 0
      t.text    :user_bio
    end

    add_index :users, :username, unique: true

    create_table :tools do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :tool_name, null: false
      t.text    :tool_description
      t.string  :tool_url
      t.text    :author_note
      t.integer :visibility, null: false, default: 0
      t.timestamps
    end

    add_index :tools, :tool_name

    create_table :lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :list_name, null: false
      t.integer :list_type, null: false, default: 0
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end

    create_table :comments do |t|
      t.references :tool, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text    :comment, null: false
      t.integer :comment_type, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.references :parent, foreign_key: { to_table: :comments }
      t.boolean :solved, null: false, default: false

      t.timestamps
    end

    create_table :tags do |t|
      t.string  :tag_name, null: false
      t.text    :tag_description
      t.integer :tag_type, null: false, default: 0
      t.references :parent, foreign_key: { to_table: :tags }

      t.timestamps
    end

    add_index :tags, :tag_name

    create_table :tool_tags do |t|
      t.references :tool, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tool_tags, [:tool_id, :tag_id], unique: true

    create_table :list_tools do |t|
      t.references :list, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: true

      t.timestamps
    end

    add_index :list_tools, [:list_id, :tool_id], unique: true

    create_table :user_tools do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: true
      t.datetime :read_at
      t.boolean  :upvote, null: false, default: false
      t.boolean  :favorite, null: false, default: false
      t.boolean  :subscribe, null: false, default: false

      t.timestamps
    end

    add_index :user_tools, [:user_id, :tool_id], unique: true

    create_table :comment_upvotes do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :comment_upvotes, [:comment_id, :user_id], unique: true
  end
end

