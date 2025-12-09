require "test_helper"

class ToolTagTest < ActiveSupport::TestCase
  # Validations
  test "should require tool" do
    tag = create(:tag)
    tool_tag = ToolTag.new(tag: tag)
    assert_not tool_tag.valid?
    assert_includes tool_tag.errors[:tool], "must exist"
  end

  test "should require tag" do
    tool = create(:tool)
    tool_tag = ToolTag.new(tool: tool)
    assert_not tool_tag.valid?
    assert_includes tool_tag.errors[:tag], "must exist"
  end

  test "should enforce uniqueness of tool_id and tag_id combination" do
    tool = create(:tool)
    tag = create(:tag)
    create(:tool_tag, tool: tool, tag: tag)

    duplicate = build(:tool_tag, tool: tool, tag: tag)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tool_id], "has already been taken"
  end

  # Associations
  test "should belong to tool" do
    tool = create(:tool)
    tag = create(:tag)
    tool_tag = create(:tool_tag, tool: tool, tag: tag)
    assert_equal tool, tool_tag.tool
  end

  test "should belong to tag" do
    tool = create(:tool)
    tag = create(:tag)
    tool_tag = create(:tool_tag, tool: tool, tag: tag)
    assert_equal tag, tool_tag.tag
  end
end

