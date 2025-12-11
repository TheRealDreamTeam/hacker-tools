require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "display_user_name should return username for active user" do
    user = create(:user, username: "testuser", email: "test@example.com")
    assert_equal "testuser", display_user_name(user)
  end

  test "display_user_name should return 'Deleted Account' for deleted user" do
    user = create(:user, user_status: :deleted)
    assert_equal I18n.t("users.deleted_account"), display_user_name(user)
  end

  test "display_user_name should return 'Deleted Account' for nil user" do
    assert_equal I18n.t("users.deleted_account"), display_user_name(nil)
  end

  test "display_user_name should handle deleted user with anonymized credentials" do
    user = create(:user)
    user.soft_delete!
    
    assert_equal I18n.t("users.deleted_account"), display_user_name(user)
  end
end

