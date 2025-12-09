class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    base_scope = Tool.public_tools.includes(:tags)

    @trending_tools = base_scope
      .left_joins(:user_tools)
      .where(user_tools: { upvote: true })
      .where("user_tools.created_at >= ?", 30.days.ago)
      .select("tools.*, COUNT(user_tools.id) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)

    @new_hot_tools = base_scope
      .where("tools.created_at >= ?", 7.days.ago)
      .left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)

    @most_upvoted_tools = base_scope
      .left_joins(:user_tools)
      .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote THEN 1 ELSE 0 END), 0) AS upvotes_count")
      .group("tools.id")
      .order("upvotes_count DESC, tools.created_at DESC")
      .limit(10)
  end
end
