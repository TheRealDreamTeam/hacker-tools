class ToolsController < ApplicationController
  before_action :set_tool, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]

  # GET /tools
  def index
    @tools = Tool.includes(:user).order(created_at: :desc)
  end

  # GET /tools/:id
  def show
    @sort_by = params[:sort_by] || "recent"
    @sort_by_flags = params[:sort_by_flags] || "recent"
    @sort_by_bugs = params[:sort_by_bugs] || "recent"

    # Load comments with upvote counts and user upvote status
    comments_base = @tool.comments.comment_type_comment.top_level.includes(:user, :comment_upvotes, replies: [:user, :comment_upvotes])
    @comments = apply_sort(comments_base, @sort_by)

    # Load flags with upvote counts
    flags_base = @tool.comments.comment_type_flag.includes(:user, :comment_upvotes)
    @flags = apply_sort(flags_base, @sort_by_flags)
    # For flags, show unsolved first when sorting by recent
    @flags = @flags.order(solved: :asc) if @sort_by_flags == "recent"

    # Load bugs with upvote counts
    bugs_base = @tool.comments.comment_type_bug.includes(:user, :comment_upvotes)
    @bugs = apply_sort(bugs_base, @sort_by_bugs)
    # For bugs, show unsolved first when sorting by recent
    @bugs = @bugs.order(solved: :asc) if @sort_by_bugs == "recent"

    @new_comment = @tool.comments.new(comment_type: :comment)
    @new_flag = @tool.comments.new(comment_type: :flag)
    @new_bug = @tool.comments.new(comment_type: :bug)
  end

  # GET /tools/new
  def new
    @tool = current_user.tools.new
  end

  # GET /tools/:id/edit
  def edit
  end

  # POST /tools
  def create
    @tool = current_user.tools.new(tool_params)

    if @tool.save
      redirect_to @tool, notice: t("tools.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tools/:id
  def update
    if @tool.update(tool_params)
      redirect_to @tool, notice: t("tools.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tools/:id
  def destroy
    @tool.destroy
    redirect_to tools_path, notice: t("tools.flash.destroyed")
  end

  private

  def set_tool
    @tool = Tool.find(params[:id])
  end

  # Ensure only the owner can modify or delete.
  def authorize_owner!
    return if @tool.user == current_user

    redirect_to tools_path, alert: t("tools.flash.unauthorized")
  end

  def tool_params
    params.require(:tool).permit(:tool_url, :author_note)
  end

  def apply_sort(collection, sort_by)
    case sort_by
    when "most_upvoted"
      # For most_upvoted, we need to handle the GROUP BY properly
      # Use a subquery or reorder to maintain the grouping
      collection.most_upvoted
    when "trending"
      collection.trending
    else # "recent" or default
      collection.recent
    end
  end
end

