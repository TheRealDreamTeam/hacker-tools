class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @query = params[:query]&.strip
    @category = params[:category] || "trending"
    base_scope = Tool.public_tools.includes(:tags, :user_tools)

    # Apply search query filter if present (search in tool name, description, and tags)
    if @query.present?
      base_scope = base_scope.left_joins(:tags).where(
        "tools.tool_name ILIKE ? OR tools.tool_description ILIKE ? OR tags.tag_name ILIKE ?",
        "%#{@query}%", "%#{@query}%", "%#{@query}%"
      ).distinct
    end

    # Trending: Tools with most upvotes in the last 30 days
    @trending_tools = base_scope
      .left_joins(:user_tools)
      .where("user_tools.upvote = ? AND user_tools.created_at >= ?", true, 30.days.ago)
      .select("tools.*, COUNT(user_tools.id) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)

    # New & Hot: Tools submitted in last 7 days, ranked by upvotes
    @new_hot_tools = base_scope
      .where("tools.created_at >= ?", 7.days.ago)
      .left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)

    # Most Upvoted: Tools with most upvotes total
    @most_upvoted_tools = base_scope
      .left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
