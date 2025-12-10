require "application_system_test_case"

class AccountDeletionTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "delete_test@example.com", password: "password123")
  end

  test "user can soft delete their account via UI" do
    visit new_user_session_path
    
    fill_in "Email", with: "delete_test@example.com"
    fill_in "Password", with: "password123"
    click_button I18n.t("devise.sessions.new.sign_in")
    
    visit account_settings_path
    
    # Find and click delete account button
    click_button I18n.t("account_settings.destroy.button")
    
    # Fill in password in modal
    within "#delete-account-modal" do
      fill_in "Password", with: "password123"
      click_button I18n.t("account_settings.destroy.confirm_button")
    end
    
    # Should be redirected to home page
    assert_current_path root_path
    assert_text I18n.t("account_settings.destroy.success")
    
    # Verify user is signed out
    assert_no_text I18n.t("profiles.show.title")
    
    # Verify soft delete in database
    @user.reload
    assert @user.deleted?
    assert_equal "deleted_user_#{@user.id}", @user.username
    assert_equal "deleted_#{@user.id}@deleted.local", @user.email
  end

  test "user cannot delete account with incorrect password" do
    visit new_user_session_path
    
    fill_in "Email", with: "delete_test@example.com"
    fill_in "Password", with: "password123"
    click_button I18n.t("devise.sessions.new.sign_in")
    
    visit account_settings_path
    
    click_button I18n.t("account_settings.destroy.button")
    
    # Fill in wrong password
    within "#delete-account-modal" do
      fill_in "Password", with: "wrong_password"
      click_button I18n.t("account_settings.destroy.confirm_button")
    end
    
    # Should still be on account settings page
    assert_current_path account_settings_path
    
    # Modal should still be open with error message visible
    within "#delete-account-modal" do
      assert_text I18n.t("account_settings.destroy.invalid_password")
    end
    
    # User should still be signed in
    assert_text I18n.t("account_settings.title")
    
    # User should not be deleted
    @user.reload
    assert_not @user.deleted?
  end

  test "deleted user cannot log in" do
    @user.soft_delete!
    
    visit new_user_session_path
    
    fill_in "Email", with: "delete_test@example.com"
    fill_in "Password", with: "password123"
    click_button I18n.t("devise.sessions.new.sign_in")
    
    # Should show error message
    assert_text I18n.t("devise.failure.deleted")
    assert_current_path new_user_session_path
  end

  test "deleted user credentials can be reused for new account" do
    original_username = @user.username
    original_email = @user.email
    
    @user.soft_delete!
    
    # Try to sign up with same credentials
    visit new_user_registration_path
    
    fill_in "Email", with: original_email
    fill_in "Username", with: original_username
    fill_in "Password", with: "newpassword123"
    fill_in "Password confirmation", with: "newpassword123"
    
    click_button I18n.t("devise.registrations.new.sign_up")
    
    # Should successfully create new account
    assert_text I18n.t("devise.registrations.signed_up")
    
    # Verify new user was created
    new_user = User.find_by(email: original_email)
    assert_not_nil new_user
    assert_not new_user.deleted?
    assert_equal original_username, new_user.username
  end
end

