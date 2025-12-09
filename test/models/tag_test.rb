require "test_helper"

class TagTest < ActiveSupport::TestCase
  # Validations
  test "should require tag_name" do
    tag = Tag.new
    assert_not tag.valid?
    assert_includes tag.errors[:tag_name], "can't be blank"
  end

  test "should require unique tag_name" do
    tag1 = create(:tag, tag_name: "ruby")
    tag2 = build(:tag, tag_name: "ruby")
    assert_not tag2.valid?
    assert_includes tag2.errors[:tag_name], "has already been taken"
  end

  # Associations
  test "should belong to parent tag" do
    parent_tag = create(:tag, tag_name: "parent")
    child_tag = create(:tag, tag_name: "child", parent: parent_tag)

    assert_equal parent_tag, child_tag.parent
  end

  test "should have many children tags" do
    parent_tag = create(:tag, tag_name: "parent")
    child1 = create(:tag, tag_name: "child1", parent: parent_tag)
    child2 = create(:tag, tag_name: "child2", parent: parent_tag)

    assert_equal 2, parent_tag.children.count
    assert_includes parent_tag.children, child1
    assert_includes parent_tag.children, child2
  end

  test "should have many tool_tags" do
    tag = create(:tag)
    tool = create(:tool)
    tool_tag = create(:tool_tag, tag: tag, tool: tool)

    assert_equal 1, tag.tool_tags.count
    assert_includes tag.tool_tags, tool_tag
  end

  test "should have many tools through tool_tags" do
    tag = create(:tag)
    tool1 = create(:tool)
    tool2 = create(:tool)
    create(:tool_tag, tag: tag, tool: tool1)
    create(:tool_tag, tag: tag, tool: tool2)

    # Access the association to ensure it's executed
    tools = tag.tools.to_a
    assert_equal 2, tools.count
    assert_includes tools, tool1
    assert_includes tools, tool2
  end

  # Dependent destroy/nullify
  test "should nullify parent_id when parent is destroyed" do
    parent_tag = create(:tag, tag_name: "parent")
    child_tag = create(:tag, tag_name: "child", parent: parent_tag)

    parent_tag.destroy
    child_tag.reload

    assert_nil child_tag.parent_id
  end

  test "should destroy associated tool_tags when tag is destroyed" do
    tag = create(:tag)
    tool = create(:tool)
    tool_tag = create(:tool_tag, tag: tag, tool: tool)

    assert_difference "ToolTag.count", -1 do
      tag.destroy
    end
  end

  # Hierarchical relationships
  test "should allow nested tag hierarchies" do
    parent = create(:tag, tag_name: "programming")
    child = create(:tag, tag_name: "ruby", parent: parent)
    grandchild = create(:tag, tag_name: "rails", parent: child)

    assert_equal parent, child.parent
    assert_equal child, grandchild.parent
    assert_includes parent.children, child
    assert_includes child.children, grandchild
  end
end

