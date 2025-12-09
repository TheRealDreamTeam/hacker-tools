require "test_helper"

class ListTest < ActiveSupport::TestCase
  # Validations
  test "should require list_name" do
    user = create(:user)
    list = List.new(user: user)
    assert_not list.valid?
    assert_includes list.errors[:list_name], "can't be blank"
  end

  test "should require user" do
    list = List.new(list_name: "My List")
    assert_not list.valid?
    assert_includes list.errors[:user], "must exist"
  end

  # Associations
  test "should belong to user" do
    user = create(:user)
    list = create(:list, user: user)
    assert_equal user, list.user
  end

  test "should have many list_tools" do
    list = create(:list)
    tool = create(:tool)
    list_tool = create(:list_tool, list: list, tool: tool)

    assert_equal 1, list.list_tools.count
    assert_includes list.list_tools, list_tool
  end

  test "should have many tools through list_tools" do
    list = create(:list)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:list_tool, list: list, tool: tool1)
    create(:list_tool, list: list, tool: tool2)

    # Access the association to ensure it's executed
    tools = list.tools.to_a
    assert_equal 2, tools.count
    assert_includes tools, tool1
    assert_includes tools, tool2
  end

  # Dependent destroy
  test "should destroy associated list_tools when list is destroyed" do
    list = create(:list)
    tool = create(:tool)
    list_tool = create(:list_tool, list: list, tool: tool)

    assert_difference "ListTool.count", -1 do
      list.destroy
    end
  end
end

