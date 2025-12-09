require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validations
  test "should require username" do
    user = User.new(email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "should require unique username" do
    user1 = create(:user, username: "testuser")
    user2 = build(:user, username: "testuser")
    assert_not user2.valid?
    assert_includes user2.errors[:username], "has already been taken"
  end

  test "should require unique email" do
    user1 = create(:user, email: "test@example.com")
    user2 = build(:user, email: "test@example.com")
    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end

  # Associations
  test "should have many tools" do
    user = create(:user)
    tool1 = create(:tool, user: user)
    tool2 = create(:tool, user: user)

    assert_equal 2, user.tools.count
    assert_includes user.tools, tool1
    assert_includes user.tools, tool2
  end

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
    comment1 = create(:comment, user: user, tool: tool)
    comment2 = create(:comment, user: user, tool: tool)

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
    comment = create(:comment, tool: tool)
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

  test "should have many subscribed_tools through user_tools" do
    user = create(:user)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:user_tool, user: user, tool: tool1, subscribe: true)
    create(:user_tool, user: user, tool: tool2, subscribe: false)

    # Access the association to ensure it's executed
    subscribed_tools = user.subscribed_tools.to_a
    assert_equal 1, subscribed_tools.count
    assert_includes subscribed_tools, tool1
    assert_not_includes subscribed_tools, tool2
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
  test "should destroy associated tools when user is destroyed" do
    user = create(:user)
    tool = create(:tool, user: user)

    assert_difference "Tool.count", -1 do
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
    comment = create(:comment, user: user, tool: tool)

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
end
