require "test_helper"

class ListToolTest < ActiveSupport::TestCase
  # Validations
  test "should require list" do
    tool = create(:tool)
    list_tool = ListTool.new(tool: tool)
    assert_not list_tool.valid?
    assert_includes list_tool.errors[:list], "must exist"
  end

  test "should require tool" do
    list = create(:list)
    list_tool = ListTool.new(list: list)
    assert_not list_tool.valid?
    assert_includes list_tool.errors[:tool], "must exist"
  end

  test "should enforce uniqueness of list_id and tool_id combination" do
    list = create(:list)
    tool = create(:tool)
    create(:list_tool, list: list, tool: tool)

    duplicate = build(:list_tool, list: list, tool: tool)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:list_id], "has already been taken"
  end

  # Associations
  test "should belong to list" do
    list = create(:list)
    tool = create(:tool)
    list_tool = create(:list_tool, list: list, tool: tool)
    assert_equal list, list_tool.list
  end

  test "should belong to tool" do
    list = create(:list)
    tool = create(:tool)
    list_tool = create(:list_tool, list: list, tool: tool)
    assert_equal tool, list_tool.tool
  end
end

