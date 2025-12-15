class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @query = params[:query]&.strip
    @category = params[:category] || "trending"

    # Redirect searches to dedicated search page
    if @query.present?
      return redirect_to search_path(query: @query), status: :see_other
    end

    # Get mixed results for each category
    @trending_items = get_trending_items
    @new_hot_items = get_new_hot_items
    @most_upvoted_items = get_most_upvoted_items

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  # Get trending items (tools + submissions) from last 30 days
  def get_trending_items
    # Get trending tools (most upvotes in last 30 days)
    trending_tools = Tool.public_tools
                         .left_joins(:user_tools)
                         .where("user_tools.upvote = ? AND user_tools.created_at >= ?", true, 30.days.ago)
                         .select("tools.*, COUNT(user_tools.id) AS upvotes_count")
                         .group("tools.id")
                         .order("upvotes_count DESC, tools.created_at DESC")
                         .limit(10)
                         .includes(:tags, :user_tools)

    # Get trending submissions (most upvoted in last 30 days)
    # Note: Eager load after grouping to avoid GROUP BY conflicts
    # First get IDs and upvote counts from grouped query in one call
    trending_data = Submission.trending.limit(10).pluck(:id, Arel.sql("COUNT(user_submissions.id)"))
    trending_submission_ids = trending_data.map(&:first)
    upvotes_map = trending_data.to_h
    
    # Load full records with associations, preserving order
    submissions_by_id = Submission.where(id: trending_submission_ids)
                                  .includes(:user, :tools, :tags, :user_submissions)
                                  .index_by(&:id)
    trending_submissions = trending_submission_ids.map { |id| submissions_by_id[id] }.compact
    # Add upvotes_count as virtual attribute
    trending_submissions.each { |s| s.define_singleton_method(:upvotes_count) { upvotes_map[s.id] || 0 } }

    combine_and_rank_items(trending_tools.to_a, trending_submissions)
  end

  # Get new & hot items (tools + submissions) from last 7 days
  def get_new_hot_items
    # Get new & hot tools (created in last 7 days, ranked by upvotes)
    new_hot_tools = Tool.public_tools
                        .where("tools.created_at >= ?", 7.days.ago)
                        .left_joins(:user_tools)
                        .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
                        .group("tools.id")
                        .order("upvotes_count DESC, tools.created_at DESC")
                        .limit(10)
                        .includes(:tags, :user_tools)

    # Get new & hot submissions (created in last 7 days, ranked by upvotes)
    # Note: Eager load after grouping to avoid GROUP BY conflicts
    # First get IDs and upvote counts from grouped query in one call
    new_hot_data = Submission.new_hot.limit(10).pluck(:id, Arel.sql("COALESCE(SUM(CASE WHEN user_submissions.upvote = true THEN 1 ELSE 0 END), 0)"))
    new_hot_submission_ids = new_hot_data.map(&:first)
    upvotes_map = new_hot_data.to_h
    
    # Load full records with associations, preserving order
    submissions_by_id = Submission.where(id: new_hot_submission_ids)
                                  .includes(:user, :tools, :tags, :user_submissions)
                                  .index_by(&:id)
    new_hot_submissions = new_hot_submission_ids.map { |id| submissions_by_id[id] }.compact
    # Add upvotes_count as virtual attribute
    new_hot_submissions.each { |s| s.define_singleton_method(:upvotes_count) { upvotes_map[s.id] || 0 } }

    combine_and_rank_items(new_hot_tools.to_a, new_hot_submissions)
  end

  # Get most upvoted items (tools + submissions) all time
  def get_most_upvoted_items
    # Get most upvoted tools
    most_upvoted_tools = Tool.public_tools
                             .left_joins(:user_tools)
                             .select("tools.*, COALESCE(SUM(CASE WHEN user_tools.upvote = true THEN 1 ELSE 0 END), 0) AS upvotes_count")
                             .group("tools.id")
                             .order("upvotes_count DESC, tools.created_at DESC")
                             .limit(10)
                             .includes(:tags, :user_tools)

    # Get most upvoted submissions
    # Note: Eager load after grouping to avoid GROUP BY conflicts
    # First get IDs and upvote counts from grouped query in one call
    most_upvoted_data = Submission.most_upvoted.limit(10).pluck(:id, Arel.sql("COALESCE(SUM(CASE WHEN user_submissions.upvote = true THEN 1 ELSE 0 END), 0)"))
    most_upvoted_submission_ids = most_upvoted_data.map(&:first)
    upvotes_map = most_upvoted_data.to_h
    
    # Load full records with associations, preserving order
    submissions_by_id = Submission.where(id: most_upvoted_submission_ids)
                                  .includes(:user, :tools, :tags, :user_submissions)
                                  .index_by(&:id)
    most_upvoted_submissions = most_upvoted_submission_ids.map { |id| submissions_by_id[id] }.compact
    # Add upvotes_count as virtual attribute
    most_upvoted_submissions.each { |s| s.define_singleton_method(:upvotes_count) { upvotes_map[s.id] || 0 } }

    combine_and_rank_items(most_upvoted_tools.to_a, most_upvoted_submissions)
  end

  # Combine tools and submissions into a unified array with type indicators
  # Items are sorted by engagement (upvotes for both tools and submissions)
  def combine_and_rank_items(tools, submissions)
    items = []

    # Add tools with type indicator
    tools.each do |tool|
      upvotes = tool.respond_to?(:upvotes_count) ? tool.upvotes_count.to_i : 0
      items << {
        type: :tool,
        item: tool,
        engagement: upvotes,
        created_at: tool.created_at
      }
    end

    # Add submissions with type indicator
    submissions.each do |submission|
      upvotes = submission.respond_to?(:upvotes_count) ? submission.upvotes_count.to_i : 0
      items << {
        type: :submission,
        item: submission,
        engagement: upvotes,
        created_at: submission.created_at
      }
    end

    # Sort by engagement (descending), then by created_at (descending)
    items.sort_by { |i| [-i[:engagement], -i[:created_at].to_i] }
  end
end
