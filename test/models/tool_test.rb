require "test_helper"

class ToolTest < ActiveSupport::TestCase
  # Validations
  test "should require tool_name" do
    tool = Tool.new
    assert_not tool.valid?
    assert_includes tool.errors[:tool_name], "can't be blank"
  end

  # Note: Tools are now community-owned, not user-owned
  # Users submit content (submissions) about tools, but don't own the tools themselves

  test "should have many comments" do
    tool = create(:tool)
    comment1 = create(:comment, commentable: tool)
    comment2 = create(:comment, commentable: tool)

    assert_equal 2, tool.comments.count
    assert_includes tool.comments, comment1
    assert_includes tool.comments, comment2
  end

  test "should have many submissions" do
    tool = create(:tool)
    user = create(:user)
    submission1 = create(:submission, user: user, tool: tool)
    submission2 = create(:submission, user: user, tool: tool)

    assert_equal 2, tool.submissions.count
    assert_includes tool.submissions, submission1
    assert_includes tool.submissions, submission2
  end

  test "should have many tool_tags" do
    tool = create(:tool)
    tag = create(:tag)
    tool_tag = create(:tool_tag, tool: tool, tag: tag)

    assert_equal 1, tool.tool_tags.count
    assert_includes tool.tool_tags, tool_tag
  end

  test "should have many tags through tool_tags" do
    tool = create(:tool)
    tag1 = create(:tag)
    tag2 = create(:tag)
    create(:tool_tag, tool: tool, tag: tag1)
    create(:tool_tag, tool: tool, tag: tag2)

    # Access the association to ensure it's executed
    tags = tool.tags.to_a
    assert_equal 2, tags.count
    assert_includes tags, tag1
    assert_includes tags, tag2
  end

  test "should have many list_tools" do
    tool = create(:tool)
    list = create(:list)
    list_tool = create(:list_tool, tool: tool, list: list)

    assert_equal 1, tool.list_tools.count
    assert_includes tool.list_tools, list_tool
  end

  test "should have many lists through list_tools" do
    tool = create(:tool)
    list1 = create(:list)
    list2 = create(:list)
    create(:list_tool, tool: tool, list: list1)
    create(:list_tool, tool: tool, list: list2)

    # Access the association to ensure it's executed
    lists = tool.lists.to_a
    assert_equal 2, lists.count
    assert_includes lists, list1
    assert_includes lists, list2
  end

  test "should have many user_tools" do
    tool = create(:tool)
    user = create(:user)
    user_tool = create(:user_tool, tool: tool, user: user)

    assert_equal 1, tool.user_tools.count
    assert_includes tool.user_tools, user_tool
  end

  # Through associations for user interactions
  test "should have many upvoters through user_tools" do
    tool = create(:tool)
    user1 = create(:user)
    user2 = create(:user)
    create(:user_tool, tool: tool, user: user1, upvote: true)
    create(:user_tool, tool: tool, user: user2, upvote: false)

    # Access the association to ensure it's executed
    upvoters = tool.upvoters.to_a
    assert_equal 1, upvoters.count
    assert_includes upvoters, user1
    assert_not_includes upvoters, user2
  end

  test "should have many favoriters through user_tools" do
    tool = create(:tool)
    user1 = create(:user)
    user2 = create(:user)
    create(:user_tool, tool: tool, user: user1, favorite: true)
    create(:user_tool, tool: tool, user: user2, favorite: false)

    # Access the association to ensure it's executed
    favoriters = tool.favoriters.to_a
    assert_equal 1, favoriters.count
    assert_includes favoriters, user1
    assert_not_includes favoriters, user2
  end

  test "should have many followers through follows" do
    tool = create(:tool)
    user1 = create(:user)
    user2 = create(:user)
    create(:follow, followable: tool, user: user1)

    followers = tool.followers.to_a
    assert_equal 1, followers.count
    assert_includes followers, user1
    assert_not_includes followers, user2
  end

  # Scopes
  test "public_tools scope should return only public tools" do
    public_tool = create(:tool, visibility: 0)
    private_tool = create(:tool, visibility: 1)

    # Actually call the scope and iterate to ensure it's executed
    public_tools = Tool.public_tools.to_a
    assert_includes public_tools, public_tool
    assert_not_includes public_tools, private_tool
  end

  test "recent scope should order by created_at desc" do
    tool1 = create(:tool, created_at: 2.days.ago)
    tool2 = create(:tool, created_at: 1.day.ago)
    tool3 = create(:tool, created_at: Time.current)

    # Actually call the scope and iterate to ensure it's executed
    recent_tools = Tool.recent.to_a
    assert_equal tool3, recent_tools.first
    assert_equal tool1, recent_tools.last
  end

  test "most_upvoted scope should order by upvote count" do
    tool1 = create(:tool)
    tool2 = create(:tool)
    tool3 = create(:tool)

    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)

    # tool2 has 3 upvotes
    create(:user_tool, tool: tool2, user: user1, upvote: true)
    create(:user_tool, tool: tool2, user: user2, upvote: true)
    create(:user_tool, tool: tool2, user: user3, upvote: true)

    # tool1 has 1 upvote
    create(:user_tool, tool: tool1, user: user1, upvote: true)

    # tool3 has 2 upvotes
    create(:user_tool, tool: tool3, user: user1, upvote: true)
    create(:user_tool, tool: tool3, user: user2, upvote: true)

    # Actually call the scope and iterate to ensure it's executed
    most_upvoted = Tool.most_upvoted.to_a
    assert_equal tool2, most_upvoted.first
    assert_equal tool3, most_upvoted.second
    assert_equal tool1, most_upvoted.third
  end

  # Dependent destroy
  test "should destroy associated comments when tool is destroyed" do
    tool = create(:tool)
    comment = create(:comment, commentable: tool)

    assert_difference "Comment.count", -1 do
      tool.destroy
    end
  end

  test "should destroy associated tool_tags when tool is destroyed" do
    tool = create(:tool)
    tag = create(:tag)
    tool_tag = create(:tool_tag, tool: tool, tag: tag)

    assert_difference "ToolTag.count", -1 do
      tool.destroy
    end
  end

  test "should destroy associated list_tools when tool is destroyed" do
    tool = create(:tool)
    list = create(:list)
    list_tool = create(:list_tool, tool: tool, list: list)

    assert_difference "ListTool.count", -1 do
      tool.destroy
    end
  end

  test "should destroy associated user_tools when tool is destroyed" do
    tool = create(:tool)
    user = create(:user)
    user_tool = create(:user_tool, tool: tool, user: user)

    assert_difference "UserTool.count", -1 do
      tool.destroy
    end
  end
end

