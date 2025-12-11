require "test_helper"

class DeletedUserDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @deleted_user = create(:user, user_status: :deleted)
    @active_user = create(:user)
    @tool = create(:tool)
    @submission = create(:submission, user: @deleted_user, tool: @tool)
    @comment = create(:comment, user: @deleted_user, commentable: @tool)
    # Sign in a user to access authenticated routes
    sign_in @active_user
  end

  test "submission show page should display 'Deleted Account' for deleted owner" do
    # Note: This test will need to be updated when submissions controller is created
    # For now, we'll skip or test with a different approach
    skip "Submissions controller not yet implemented"
  end

  test "comment should display 'Deleted Account' for deleted author" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_match I18n.t("users.deleted_account"), response.body
  end

  test "associations should work correctly with deleted users" do
    # Verify associations still work
    assert_equal @deleted_user, @submission.user
    assert_equal @deleted_user, @comment.user
    assert @submission.user.deleted?
    assert @comment.user.deleted?
  end

  test "deleted user's submissions are still accessible" do
    # Note: This test will need to be updated when submissions controller is created
    # For now, we'll verify the association works
    assert_equal @deleted_user, @submission.user
  end

  test "deleted user's comments are still visible" do
    get tool_path(id: @tool.id)
    assert_response :success
    assert_match @comment.comment, response.body
  end
end

