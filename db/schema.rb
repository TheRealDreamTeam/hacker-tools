# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_12_014156) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comment_upvotes", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id", "user_id"], name: "index_comment_upvotes_on_comment_id_and_user_id", unique: true
    t.index ["comment_id"], name: "index_comment_upvotes_on_comment_id"
    t.index ["user_id"], name: "index_comment_upvotes_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "comment", null: false
    t.integer "comment_type", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.bigint "parent_id"
    t.boolean "solved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable"
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id"
    t.index ["user_id", "followable_type", "followable_id"], name: "index_follows_on_user_id_and_followable_type_and_followable_id", unique: true
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "list_submissions", force: :cascade do |t|
    t.bigint "list_id", null: false
    t.bigint "submission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id", "submission_id"], name: "index_list_submissions_on_list_id_and_submission_id", unique: true
    t.index ["list_id"], name: "index_list_submissions_on_list_id"
    t.index ["submission_id"], name: "index_list_submissions_on_submission_id"
  end

  create_table "list_tools", force: :cascade do |t|
    t.bigint "list_id", null: false
    t.bigint "tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id", "tool_id"], name: "index_list_tools_on_list_id_and_tool_id", unique: true
    t.index ["list_id"], name: "index_list_tools_on_list_id"
    t.index ["tool_id"], name: "index_list_tools_on_tool_id"
  end

  create_table "lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "list_name", null: false
    t.integer "list_type", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_lists_on_user_id"
  end

  create_table "submission_tags", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "tag_id"], name: "index_submission_tags_on_submission_id_and_tag_id", unique: true
    t.index ["submission_id"], name: "index_submission_tags_on_submission_id"
    t.index ["tag_id"], name: "index_submission_tags_on_tag_id"
  end

  create_table "submission_tools", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "tool_id"], name: "index_submission_tools_on_submission_id_and_tool_id", unique: true
    t.index ["submission_id"], name: "index_submission_tools_on_submission_id"
    t.index ["tool_id"], name: "index_submission_tools_on_tool_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "submission_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "submission_url"
    t.string "normalized_url"
    t.text "author_note"
    t.string "submission_name"
    t.text "submission_description"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "duplicate_of_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duplicate_of_id"], name: "index_submissions_on_duplicate_of_id"
    t.index ["metadata"], name: "index_submissions_on_metadata", using: :gin
    t.index ["normalized_url", "user_id"], name: "index_submissions_on_normalized_url_and_user_id", unique: true, where: "(normalized_url IS NOT NULL)"
    t.index ["processed_at"], name: "index_submissions_on_processed_at"
    t.index ["status", "submission_type"], name: "index_submissions_on_status_and_submission_type"
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["submission_type"], name: "index_submissions_on_submission_type"
    t.index ["user_id", "status"], name: "index_submissions_on_user_id_and_status"
  end

  create_table "tags", force: :cascade do |t|
    t.string "tag_name", null: false
    t.text "tag_description"
    t.integer "tag_type", default: 0, null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_tags_on_parent_id"
    t.index ["tag_name"], name: "index_tags_on_tag_name"
  end

  create_table "tool_tags", force: :cascade do |t|
    t.bigint "tool_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tool_tags_on_tag_id"
    t.index ["tool_id", "tag_id"], name: "index_tool_tags_on_tool_id_and_tag_id", unique: true
    t.index ["tool_id"], name: "index_tool_tags_on_tool_id"
  end

  create_table "tools", force: :cascade do |t|
    t.string "tool_name", null: false
    t.text "tool_description"
    t.string "tool_url"
    t.text "author_note"
    t.integer "visibility", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_name"], name: "index_tools_on_tool_name"
  end

  create_table "user_submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "submission_id", null: false
    t.datetime "read_at"
    t.boolean "upvote", default: false, null: false
    t.boolean "favorite", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id", "upvote"], name: "index_user_submissions_on_submission_id_and_upvote", where: "(upvote = true)"
    t.index ["submission_id"], name: "index_user_submissions_on_submission_id"
    t.index ["user_id", "submission_id"], name: "index_user_submissions_on_user_id_and_submission_id", unique: true
    t.index ["user_id"], name: "index_user_submissions_on_user_id"
  end

  create_table "user_tools", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tool_id", null: false
    t.datetime "read_at"
    t.boolean "upvote", default: false, null: false
    t.boolean "favorite", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tool_id"], name: "index_user_tools_on_tool_id"
    t.index ["user_id", "tool_id"], name: "index_user_tools_on_user_id_and_tool_id", unique: true
    t.index ["user_id"], name: "index_user_tools_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.integer "user_type", default: 0, null: false
    t.integer "user_status", default: 0, null: false
    t.text "user_bio"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "comment_upvotes", "comments"
  add_foreign_key "comment_upvotes", "users"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "users"
  add_foreign_key "follows", "users"
  add_foreign_key "list_submissions", "lists"
  add_foreign_key "list_submissions", "submissions"
  add_foreign_key "list_tools", "lists"
  add_foreign_key "list_tools", "tools"
  add_foreign_key "lists", "users"
  add_foreign_key "submission_tags", "submissions"
  add_foreign_key "submission_tags", "tags"
  add_foreign_key "submission_tools", "submissions"
  add_foreign_key "submission_tools", "tools"
  add_foreign_key "submissions", "submissions", column: "duplicate_of_id"
  add_foreign_key "submissions", "users"
  add_foreign_key "tags", "tags", column: "parent_id"
  add_foreign_key "tool_tags", "tags"
  add_foreign_key "tool_tags", "tools"
  add_foreign_key "user_submissions", "submissions"
  add_foreign_key "user_submissions", "users"
  add_foreign_key "user_tools", "tools"
  add_foreign_key "user_tools", "users"
end
