class DashboardController < ApplicationController
  # Auth enforced in ApplicationController; dashboard is private to the signed-in user.
  def show
    @user = current_user

    # Lightweight, paged-ready slices for the dashboard cards. Keep queries small to
    # avoid slowing the landing experience; paginate per section later if needed.
    @recent_tools = @user.tools.order(created_at: :desc).limit(5)
    @recent_lists = @user.lists.order(created_at: :desc).limit(5)
    @recent_comments = @user.comments.includes(:tool).order(created_at: :desc).limit(5)
    @favorited_tools = @user.favorited_tools.includes(:user).order(created_at: :desc).limit(5)
    @subscribed_tools = @user.subscribed_tools.includes(:user).order(created_at: :desc).limit(5)
  end
end

