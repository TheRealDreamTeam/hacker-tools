require "test_helper"

class UserToolTest < ActiveSupport::TestCase
  # Validations
  test "should require user" do
    tool = create(:tool)
    user_tool = UserTool.new(tool: tool)
    assert_not user_tool.valid?
    assert_includes user_tool.errors[:user], "must exist"
  end

  test "should require tool" do
    user = create(:user)
    user_tool = UserTool.new(user: user)
    assert_not user_tool.valid?
    assert_includes user_tool.errors[:tool], "must exist"
  end

  test "should enforce uniqueness of user_id and tool_id combination" do
    user = create(:user)
    tool = create(:tool)
    create(:user_tool, user: user, tool: tool)

    duplicate = build(:user_tool, user: user, tool: tool)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  # Associations
  test "should belong to user" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool)
    assert_equal user, user_tool.user
  end

  test "should belong to tool" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool)
    assert_equal tool, user_tool.tool
  end

  # Default values
  test "should default upvote to false" do
    user = create(:user)
    tool = create(:tool)
    user_tool = UserTool.create(user: user, tool: tool)
    assert_equal false, user_tool.upvote
  end

  test "should default favorite to false" do
    user = create(:user)
    tool = create(:tool)
    user_tool = UserTool.create(user: user, tool: tool)
    assert_equal false, user_tool.favorite
  end

  # Boolean flags
  test "should allow setting upvote to true" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool, upvote: true)
    assert_equal true, user_tool.upvote
  end

  test "should allow setting favorite to true" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool, favorite: true)
    assert_equal true, user_tool.favorite
  end

  test "should allow multiple flags to be true simultaneously" do
    user = create(:user)
    tool = create(:tool)
    user_tool = create(:user_tool, user: user, tool: tool, upvote: true, favorite: true)
    assert_equal true, user_tool.upvote
    assert_equal true, user_tool.favorite
  end
end

