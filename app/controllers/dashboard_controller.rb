class DashboardController < ApplicationController
  def show
    @user = current_user
  end
end
class DashboardController < ApplicationController
  # Auth enforced in ApplicationController; dashboard is private to the signed-in user.
  def show
    @user = current_user

    # Lightweight, paged-ready slices for the dashboard cards. Keep queries small to
    # avoid slowing the landing experience; paginate per section later if needed.
    # Users now submit content (submissions) about tools, not own tools
    @recent_submissions = @user.submissions.completed.order(created_at: :desc).limit(5)
    @recent_lists = @user.lists.order(created_at: :desc).limit(5)
    # Comments can be on both Tools and Submissions (polymorphic)
    @recent_comments = @user.comments.includes(:commentable).order(created_at: :desc).limit(5)
    @favorited_tools = @user.favorited_tools.order(created_at: :desc).limit(5)
    
    # Load all follow types for the tabbed interface
    # Each follow type is loaded separately to allow efficient querying and proper associations
    # Tools are community-owned (no user association), Lists have user associations
    @followed_tools = @user.followed_tools.order(created_at: :desc).limit(5)
    @followed_lists = @user.followed_lists.includes(:user).order(created_at: :desc).limit(5)
    # Tags don't have user associations, so no includes needed
    @followed_tags = @user.followed_tags.order(created_at: :desc).limit(5)
    # Users are already User records, so no includes needed
    @followed_users = @user.followed_users.order(created_at: :desc).limit(5)
  end
end

