class ToolsController < ApplicationController
  before_action :set_tool, only: %i[show edit update destroy add_tag remove_tag upvote favorite follow]
  # TODO: Re-enable authorization when we decide on permissions (admin-only or open editing)
  # before_action :authorize_owner!, only: %i[edit update destroy add_tag remove_tag]

  # GET /tools
  def index
    @tools = Tool.includes(:tags, :user_tools).order(created_at: :desc)
  end

  # GET /tools/:id
  def show
    @sort_by = params[:sort_by] || "recent"
    @sort_by_flags = params[:sort_by_flags] || "recent"
    @sort_by_bugs = params[:sort_by_bugs] || "recent"

    # Track read interaction
    touch_read_interaction

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

    # Load tags for the tool and all available tags grouped by type
    @tool_tags = @tool.tags.includes(:parent)
    @available_tags = Tag.includes(:parent).order(tag_type: :asc, tag_name: :asc)
  end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/:id/edit
  def edit
  end

  # POST /tools
  def create
    @tool = Tool.new(tool_params)

    if @tool.save
      redirect_to @tool, notice: t("tools.flash.created")
    else
      # Validation errors are displayed inline under each input field
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tools/:id
  def update
    if @tool.update(tool_params)
      redirect_to @tool, notice: t("tools.flash.updated")
    else
      # Validation errors are displayed inline under each input field
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tools/:id
  def destroy
    @tool.destroy
    redirect_to tools_path, notice: t("tools.flash.destroyed")
  end

  # POST /tools/:id/add_tag
  def add_tag
    tag = Tag.find(params[:tag_id])
    @tool.tags << tag unless @tool.tags.include?(tag)
    redirect_to tool_path(@tool), notice: t("tools.flash.tag_added")
  rescue ActiveRecord::RecordNotFound
    redirect_to tool_path(@tool), alert: t("tools.flash.tag_not_found")
  end

  # DELETE /tools/:id/remove_tag
  def remove_tag
    tag = Tag.find(params[:tag_id])
    @tool.tags.delete(tag)
    redirect_to tool_path(@tool), notice: t("tools.flash.tag_removed")
  rescue ActiveRecord::RecordNotFound
    redirect_to tool_path(@tool), alert: t("tools.flash.tag_not_found")
  end

  # POST /tools/:id/upvote
  def upvote
    toggle_interaction_flag(:upvote, :tool_upvote)
  end

  # POST /tools/:id/favorite
  def favorite
    toggle_interaction_flag(:favorite, :tool_favorite)
  end

  # POST /tools/:id/follow
  def follow
    return redirect_to new_user_session_path unless current_user

    # Toggle follow: if exists, destroy (unfollow); if not, create (follow)
    follow_record = current_user.follows.find_by(followable: @tool)
    
    if follow_record
      follow_record.destroy
    else
      # Use find_or_create_by to handle race conditions gracefully
      # The unique index at database level prevents duplicates
      current_user.follows.find_or_create_by!(followable: @tool)
    end

    respond_to do |format|
      format.turbo_stream { render "tools/interaction_update" }
      format.html { redirect_back fallback_location: tool_path(@tool), notice: t("tools.flash.tool_follow") }
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition: if another request created it between find_by and find_or_create_by
    # The follow now exists, so destroy it (toggle behavior)
    follow_record = current_user.follows.find_by(followable: @tool)
    follow_record&.destroy

    respond_to do |format|
      format.turbo_stream { render "tools/interaction_update" }
      format.html { redirect_back fallback_location: tool_path(@tool), notice: t("tools.flash.tool_follow") }
    end
  end

  private

  def set_tool
    @tool = Tool.find(params[:id])
  end

  # TODO: Re-implement authorization when we decide on permissions
  # Tools are now community-owned, so we need to decide:
  # - Admin-only editing?
  # - Open editing for all users?
  # - Some other permission model?
  # def authorize_owner!
  #   # Implementation depends on chosen permission model
  # end

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

  def touch_read_interaction
    return unless current_user

    user_tool = ensure_user_tool
    user_tool.read_at ||= Time.current
    user_tool.save if user_tool.changed?
  end

  def ensure_user_tool
    @user_tool ||= @tool.user_tools.find_or_create_by(user: current_user)
  end

  def toggle_interaction_flag(flag, i18n_key)
    return redirect_to new_user_session_path unless current_user

    user_tool = ensure_user_tool
    new_value = !user_tool.public_send(flag)
    user_tool.read_at ||= Time.current
    user_tool.update(flag => new_value, read_at: user_tool.read_at)

    respond_to do |format|
      format.turbo_stream { render "tools/interaction_update" }
      format.html { redirect_back fallback_location: tool_path(@tool), notice: t("tools.flash.#{i18n_key}") }
    end
  end
end

