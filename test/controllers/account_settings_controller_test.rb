require "test_helper"

class AccountSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "test@example.com", password: "password123")
    sign_in @user
  end

  test "should show account settings page" do
    get account_settings_path
    assert_response :success
    assert_select "h2", text: I18n.t("account_settings.title")
  end

  test "should soft delete account with correct password" do
    original_id = @user.id
    original_username = @user.username
    original_email = @user.email
    
    assert_difference "User.count", 0 do
      delete account_settings_path, params: { user: { password: "password123" } }
    end
    
    @user.reload
    assert @user.deleted?
    assert_equal "deleted_user_#{original_id}", @user.username
    assert_equal "deleted_#{original_id}@deleted.local", @user.email
    assert_redirected_to root_path
  end

  test "should not delete account with incorrect password" do
    assert_difference "User.count", 0 do
      delete account_settings_path, params: { user: { password: "wrong_password" } }
    end
    
    @user.reload
    assert_not @user.deleted?
    assert_equal :active, @user.user_status.to_sym
    assert_redirected_to account_settings_path
    # Verify error message is set
    assert_equal I18n.t("account_settings.destroy.invalid_password"), flash[:alert]
  end

  test "should sign out user after soft delete" do
    delete account_settings_path, params: { user: { password: "password123" } }
    
    # User should be signed out (can't access protected routes)
    get account_settings_path
    assert_redirected_to new_user_session_path
  end

  test "should preserve associated data after soft delete" do
    submission = create(:submission, user: @user)
    tool = create(:tool)
    comment = create(:comment, user: @user, commentable: tool)
    list = create(:list, user: @user)
    
    delete account_settings_path, params: { user: { password: "password123" } }
    
    submission.reload
    comment.reload
    list.reload
    
    assert_equal @user.id, submission.user_id
    assert_equal @user.id, comment.user_id
    assert_equal @user.id, list.user_id
    assert submission.user.deleted?
    assert comment.user.deleted?
    assert list.user.deleted?
  end

  test "should require authentication to access account settings" do
    sign_out @user
    
    get account_settings_path
    assert_redirected_to new_user_session_path
  end

  test "should require authentication to delete account" do
    sign_out @user
    
    assert_no_difference "User.count" do
      delete account_settings_path, params: { user: { password: "password123" } }
    end
    
    assert_redirected_to new_user_session_path
  end
end

