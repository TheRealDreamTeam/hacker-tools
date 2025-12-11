module ApplicationHelper
  # Display user name or "Deleted Account" for deleted users
  # Used throughout the application to show user information while handling soft-deleted accounts
  def display_user_name(user)
    return t("users.deleted_account") unless user
    return t("users.deleted_account") if user.deleted?

    user.username || user.email
  end

  # Returns the auto-dismiss time in milliseconds for flash messages
  # 5 seconds in development, 3 seconds in production
  def flash_auto_dismiss_time
    Rails.env.development? ? 5000 : 3000
  end
end
