require "test_helper"

class DeletedUserDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @deleted_user = create(:user, user_status: :deleted)
    @active_user = create(:user)
    @tool = create(:tool, user: @deleted_user)
    @comment = create(:comment, user: @deleted_user, tool: @tool)
    # Sign in a user to access authenticated routes
    sign_in @active_user
  end

  test "tool show page should display 'Deleted Account' for deleted owner" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_match I18n.t("users.deleted_account"), response.body
  end

  test "tool index page should display 'Deleted Account' for deleted owner" do
    get tools_path
    assert_response :success
    assert_match I18n.t("users.deleted_account"), response.body
  end

  test "comment should display 'Deleted Account' for deleted author" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_match I18n.t("users.deleted_account"), response.body
  end

  test "associations should work correctly with deleted users" do
    # Verify associations still work
    assert_equal @deleted_user, @tool.user
    assert_equal @deleted_user, @comment.user
    assert @tool.user.deleted?
    assert @comment.user.deleted?
  end

  test "deleted user's tools are still accessible" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_select "h1", text: @tool.tool_name
  end

  test "deleted user's comments are still visible" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_match @comment.comment, response.body
  end
end

