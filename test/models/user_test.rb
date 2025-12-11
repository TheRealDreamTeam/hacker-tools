require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validations
  test "should require username" do
    user = User.new(email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "should require unique username among active users" do
    user1 = create(:user, username: "testuser")
    user2 = build(:user, username: "testuser")
    assert_not user2.valid?
    assert_includes user2.errors[:username], "has already been taken"
  end

  test "should allow username reuse after user is deleted" do
    user1 = create(:user, username: "reusable")
    user1.soft_delete!
    
    user2 = build(:user, username: "reusable")
    assert user2.valid?
    assert user2.save
    assert_equal "reusable", user2.username
  end

  test "should require unique email among active users" do
    user1 = create(:user, email: "test@example.com")
    user2 = build(:user, email: "test@example.com")
    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end

  test "should allow email reuse after user is deleted" do
    user1 = create(:user, email: "reuse@example.com")
    user1.soft_delete!
    
    user2 = build(:user, email: "reuse@example.com")
    assert user2.valid?
    assert user2.save
    assert_equal "reuse@example.com", user2.email
  end

  # Associations
  test "should have many submissions" do
    user = create(:user)
    submission1 = create(:submission, user: user)
    submission2 = create(:submission, user: user)

    assert_equal 2, user.submissions.count
    assert_includes user.submissions, submission1
    assert_includes user.submissions, submission2
  end

  # Note: Tools are now community-owned, not user-owned
  # Users submit content (submissions) about tools, but don't own the tools themselves

  test "should have many lists" do
    user = create(:user)
    list1 = create(:list, user: user)
    list2 = create(:list, user: user)

    assert_equal 2, user.lists.count
    assert_includes user.lists, list1
    assert_includes user.lists, list2
  end

  test "should have many comments" do
    user = create(:user)
    tool = create(:tool)
    comment1 = create(:comment, user: user, commentable: tool)
    comment2 = create(:comment, user: user, commentable: tool)

    assert_equal 2, user.comments.count
    assert_includes user.comments, comment1
    assert_includes user.comments, comment2
  end

  test "should have many user_tools" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool)

    assert_equal 1, user.user_tools.count
    assert_includes user.user_tools, user_tool
  end

  test "should have many comment_upvotes" do
    user = create(:user)
    tool = create(:tool)
    comment = create(:comment, commentable: tool)
    upvote = create(:comment_upvote, user: user, comment: comment)

    assert_equal 1, user.comment_upvotes.count
    assert_includes user.comment_upvotes, upvote
  end

  # Through associations
  test "should have many upvoted_tools through user_tools" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:user_tool, user: user, tool: tool1, upvote: true)
    create(:user_tool, user: user, tool: tool2, upvote: false)

    # Access the association to ensure it's executed
    upvoted_tools = user.upvoted_tools.to_a
    assert_equal 1, upvoted_tools.count
    assert_includes upvoted_tools, tool1
    assert_not_includes upvoted_tools, tool2
  end

  test "should have many favorited_tools through user_tools" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:user_tool, user: user, tool: tool1, favorite: true)
    create(:user_tool, user: user, tool: tool2, favorite: false)

    # Access the association to ensure it's executed
    favorited_tools = user.favorited_tools.to_a
    assert_equal 1, favorited_tools.count
    assert_includes favorited_tools, tool1
    assert_not_includes favorited_tools, tool2
  end

  test "should have many followed_tools through follows" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:follow, user: user, followable: tool1)

    followed_tools = user.followed_tools.to_a
    assert_equal 1, followed_tools.count
    assert_includes followed_tools, tool1
    assert_not_includes followed_tools, tool2
  end

  # Helper methods
  test "upvoted_tools_count should return correct count" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:user_tool, user: user, tool: tool1, upvote: true)
    create(:user_tool, user: user, tool: tool2, upvote: true)

    assert_equal 2, user.upvoted_tools_count
  end

  test "favorite_count should return correct count" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:user_tool, user: user, tool: tool1, favorite: true)
    create(:user_tool, user: user, tool: tool2, favorite: true)

    assert_equal 2, user.favorite_count
  end

  # Dependent destroy
  test "should destroy associated submissions when user is destroyed" do
    user = create(:user)
    submission = create(:submission, user: user)

    assert_difference "Submission.count", -1 do
      user.destroy
    end
  end

  test "should destroy associated lists when user is destroyed" do
    user = create(:user)
    list = create(:list, user: user)

    assert_difference "List.count", -1 do
      user.destroy
    end
  end

  test "should destroy associated comments when user is destroyed" do
    user = create(:user)
    tool = create(:tool)
    comment = create(:comment, user: user, commentable: tool)

    assert_difference "Comment.count", -1 do
      user.destroy
    end
  end

  test "should destroy associated user_tools when user is destroyed" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool)

    assert_difference "UserTool.count", -1 do
      user.destroy
    end
  end

  # Soft delete functionality
  test "user_status enum should have active and deleted values" do
    user = create(:user, user_status: :active)
    assert user.active?
    assert_not user.deleted?
    
    user.user_status = :deleted
    user.save!
    assert user.deleted?
    assert_not user.active?
  end

  test "deleted? should return true for deleted users" do
    user = create(:user, user_status: :deleted)
    assert user.deleted?
  end

  test "deleted? should return false for active users" do
    user = create(:user, user_status: :active)
    assert_not user.deleted?
  end

  test "active scope should return only active users" do
    active_user = create(:user, user_status: :active)
    deleted_user = create(:user, user_status: :deleted)
    
    active_users = User.active.to_a
    assert_includes active_users, active_user
    assert_not_includes active_users, deleted_user
  end

  test "deleted scope should return only deleted users" do
    active_user = create(:user, user_status: :active)
    deleted_user = create(:user, user_status: :deleted)
    
    deleted_users = User.deleted.to_a
    assert_includes deleted_users, deleted_user
    assert_not_includes deleted_users, active_user
  end

  test "User.all should include both active and deleted users" do
    active_user = create(:user, user_status: :active)
    deleted_user = create(:user, user_status: :deleted)
    
    all_users = User.all.to_a
    assert_includes all_users, active_user
    assert_includes all_users, deleted_user
  end

  test "soft_delete! should mark user as deleted" do
    user = create(:user, user_status: :active)
    user.soft_delete!
    
    assert user.deleted?
    assert_equal "deleted", user.user_status
  end

  test "soft_delete! should anonymize username" do
    user = create(:user, username: "original_username")
    original_id = user.id
    
    user.soft_delete!
    
    assert_equal "deleted_user_#{original_id}", user.username
  end

  test "soft_delete! should anonymize email" do
    user = create(:user, email: "original@example.com")
    original_id = user.id
    
    user.soft_delete!
    
    assert_equal "deleted_#{original_id}@deleted.local", user.email
  end

  test "soft_delete! should clear authentication tokens" do
    user = create(:user)
    user.update(reset_password_token: "some_token", reset_password_sent_at: Time.current)
    
    user.soft_delete!
    
    assert_nil user.reset_password_token
    assert_nil user.reset_password_sent_at
    assert_nil user.remember_created_at
  end

  test "soft_delete! should preserve associated data" do
    user = create(:user)
    submission = create(:submission, user: user)
    tool = create(:tool)
    comment = create(:comment, user: user, commentable: tool)
    list = create(:list, user: user)
    
    user.soft_delete!
    
    submission.reload
    comment.reload
    list.reload
    
    assert_equal user.id, submission.user_id
    assert_equal user.id, comment.user_id
    assert_equal user.id, list.user_id
  end

  test "associations should work with deleted users" do
    user = create(:user)
    submission = create(:submission, user: user)
    tool = create(:tool)
    comment = create(:comment, user: user, commentable: tool)
    
    user.soft_delete!
    
    submission.reload
    comment.reload
    
    assert_equal user, submission.user
    assert_equal user, comment.user
    assert submission.user.deleted?
    assert comment.user.deleted?
  end

  test "active_for_authentication? should return false for deleted users" do
    user = create(:user, user_status: :deleted)
    assert_not user.active_for_authentication?
  end

  test "active_for_authentication? should return true for active users" do
    user = create(:user, user_status: :active)
    assert user.active_for_authentication?
  end

  test "inactive_message should return :deleted for deleted users" do
    user = create(:user, user_status: :deleted)
    assert_equal :deleted, user.inactive_message
  end

  test "inactive_message should return super for active users" do
    user = create(:user, user_status: :active)
    # For active users, inactive_message should return the default Devise message
    # which is typically :inactive or similar
    assert_not_equal :deleted, user.inactive_message
  end
end
