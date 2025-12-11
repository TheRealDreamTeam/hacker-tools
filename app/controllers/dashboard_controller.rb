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
    
    # Load all follow types for the tabbed interface
    # Each follow type is loaded separately to allow efficient querying and proper associations
    # Tools and Lists have user associations, so we include them to avoid N+1 queries
    @followed_tools = @user.followed_tools.includes(:user).order(created_at: :desc).limit(5)
    @followed_lists = @user.followed_lists.includes(:user).order(created_at: :desc).limit(5)
    # Tags don't have user associations, so no includes needed
    @followed_tags = @user.followed_tags.order(created_at: :desc).limit(5)
    # Users are already User records, so no includes needed
    @followed_users = @user.followed_users.order(created_at: :desc).limit(5)
  end
end

