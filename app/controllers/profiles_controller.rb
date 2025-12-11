class ProfilesController < ApplicationController
  # Public profile page - accessible to anyone (no authentication required)
  # Shows public-facing profile with tools, comments, and upvotes
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_user, only: [:show, :follow, :unfollow]

  # Display public profile by username
  # Route: /u/:username
  def show
    # Load public data for the profile
    # Only show public tools, comments on public tools, and upvotes on public tools
    @public_tools = @user.tools.public_tools.includes(:tags, :user).order(created_at: :desc).limit(20)
    
    # Comments on public tools only
    @public_comments = @user.comments
      .joins(:tool)
      .where(tools: { visibility: Tool.visibilities[:public] })
      .includes(:tool, :user)
      .order(created_at: :desc)
      .limit(20)
    
    # Upvoted tools that are public
    @public_upvoted_tools = @user.upvoted_tools
      .public_tools
      .includes(:user, :tags)
      .order(created_at: :desc)
      .limit(20)
    
    # Followers/Following counts - Following only includes users followed
    @followers_count = @user.followers.count
    @following_count = @user.followed_users.count
    
    # Check if current user is following this profile user (if signed in)
    @is_following = user_signed_in? && current_user.follows?(@user)
    @is_own_profile = user_signed_in? && current_user == @user
  end

  # POST /u/:username/follow
  # Follow a user (toggle: follow if not following, unfollow if already following)
  def follow
    return redirect_to new_user_session_path unless user_signed_in?
    
    # Prevent self-following
    if current_user == @user
      redirect_to profile_path(@user.username), alert: t("profiles.follow.cannot_follow_self")
      return
    end

    # Toggle follow: if exists, destroy (unfollow); if not, create (follow)
    follow_record = current_user.follows.find_by(followable: @user)
    
    if follow_record
      # Already following - unfollow
      follow_record.destroy
      message = t("profiles.follow.unfollowed", username: @user.username)
    else
      # Not following - follow (use find_or_create_by to handle race conditions)
      begin
        current_user.follows.find_or_create_by!(followable: @user)
        message = t("profiles.follow.followed", username: @user.username)
      rescue ActiveRecord::RecordInvalid => e
        # Handle validation error (e.g., self-follow attempt)
        redirect_to profile_path(@user.username), alert: e.message
        return
      end
    end

    # Reload user and clear association cache to get updated follower count
    @user.reload
    @user.association(:followers).reset
    
    # Refresh follow state for current user (clear association cache)
    current_user.association(:follows).reset if current_user.follows.loaded?

    respond_to do |format|
      format.turbo_stream { render "profiles/follow_update" }
      format.html { redirect_to profile_path(@user.username), notice: message }
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition: if another request created it between find and create
    # The follow now exists, so destroy it (toggle behavior)
    follow_record = current_user.follows.find_by(followable: @user)
    follow_record&.destroy
    @user.reload
    @user.association(:followers).reset

    respond_to do |format|
      format.turbo_stream { render "profiles/follow_update" }
      format.html { redirect_to profile_path(@user.username), notice: t("profiles.follow.unfollowed", username: @user.username) }
    end
  end

  # DELETE /u/:username/unfollow
  # Unfollow a user (alternative to toggle in follow action)
  def unfollow
    return redirect_to new_user_session_path unless user_signed_in?
    
    follow_record = current_user.follows.find_by(followable: @user)
    follow_record&.destroy
    
    # Reload user and clear association cache to get updated follower count
    @user.reload
    @user.association(:followers).reset
    
    # Refresh follow state for current user (clear association cache)
    current_user.association(:follows).reset if current_user.follows.loaded?

    respond_to do |format|
      format.turbo_stream { render "profiles/follow_update" }
      format.html { redirect_to profile_path(@user.username), notice: t("profiles.follow.unfollowed", username: @user.username) }
    end
  end

  private

  def set_user
    @user = User.active.find_by(username: params[:username])
    
    unless @user
      redirect_to root_path, alert: t("profiles.show.user_not_found")
      return
    end
  end
end

