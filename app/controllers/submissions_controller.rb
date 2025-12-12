class SubmissionsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_submission, only: %i[show edit update destroy add_tag remove_tag follow upvote favorite]
  before_action :authorize_owner!, only: %i[edit update destroy add_tag remove_tag]

  # GET /submissions
  def index
    @query = params[:query]&.strip
    @submission_type = params[:type]
    @status = params[:status] || :completed # Default to completed submissions
    
    # Use search service if query is present
    if @query.present?
      @submissions = SubmissionSearchService.search(
        @query,
        limit: params[:limit] || 20,
        submission_type: @submission_type,
        status: @status,
        use_semantic: params[:use_semantic] != "false", # Default to true
        use_fulltext: params[:use_fulltext] != "false"  # Default to true
      )
      
      # Optionally enhance results with RAG (can be slow, so make it optional)
      if params[:enhance] == "true"
        @enhanced_results = SubmissionRagService.enhance_results(@query, @submissions, top_k: 5)
      end
    else
      # Regular listing without search
      @submissions = Submission.includes(:user, :tools, :tags)
                               .order(created_at: :desc)
      
      # Filter by submission type if provided
      @submissions = @submissions.by_type(@submission_type) if @submission_type.present?
      
      # Filter by status if provided
      @submissions = @submissions.where(status: @status) if @status.present?
      
      # Filter by tool if provided
      @submissions = @submissions.for_tool(Tool.find(params[:tool_id])) if params[:tool_id].present?
    end
    
    # Eager load associations for performance
    @submissions = @submissions.includes(:user, :tools, :tags) if @submissions.is_a?(ActiveRecord::Relation)
  end

  # GET /submissions/:id
  def show
    @sort_by = params[:sort_by] || "recent"
    @sort_by_flags = params[:sort_by_flags] || "recent"
    @sort_by_bugs = params[:sort_by_bugs] || "recent"

    # Track read interaction (similar to tools)
    touch_read_interaction

    # Load comments with upvote counts and user upvote status
    comments_base = @submission.comments.comment_type_comment.top_level.includes(:user, :comment_upvotes, replies: [:user, :comment_upvotes])
    @comments = apply_sort(comments_base, @sort_by)

    # Load flags with upvote counts
    flags_base = @submission.comments.comment_type_flag.includes(:user, :comment_upvotes)
    @flags = apply_sort(flags_base, @sort_by_flags)
    @flags = @flags.order(solved: :asc) if @sort_by_flags == "recent"

    # Load bugs with upvote counts
    bugs_base = @submission.comments.comment_type_bug.includes(:user, :comment_upvotes)
    @bugs = apply_sort(bugs_base, @sort_by_bugs)
    @bugs = @bugs.order(solved: :asc) if @sort_by_bugs == "recent"

    @new_comment = @submission.comments.new(comment_type: :comment)
    @new_flag = @submission.comments.new(comment_type: :flag)
    @new_bug = @submission.comments.new(comment_type: :bug)

    # Load tags for the submission and all available tags grouped by type
    @submission_tags = @submission.tags.includes(:parent)
    @available_tags = Tag.includes(:parent).order(tag_type: :asc, tag_name: :asc)
  end

  # GET /submissions/new
  def new
    @submission = current_user.submissions.new
  end

  # GET /submissions/:id/edit
  def edit
  end

  # POST /submissions
  def create
    @submission = current_user.submissions.new(submission_params)
    
    if @submission.save
      # Queue processing pipeline job
      SubmissionProcessingJob.perform_later(@submission.id)
      
      respond_to do |format|
        format.html { redirect_to @submission, notice: t("submissions.create.success") }
        format.turbo_stream { redirect_to @submission, status: :see_other, notice: t("submissions.create.success") }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /submissions/:id
  def update
    if @submission.update(submission_params)
      respond_to do |format|
        format.html { redirect_to @submission, notice: t("submissions.update.success") }
        format.turbo_stream { render :update }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /submissions/:id
  def destroy
    @submission.destroy
    
    respond_to do |format|
      format.html { redirect_to submissions_path, notice: t("submissions.destroy.success") }
      format.turbo_stream { render :destroy }
    end
  end

  # POST /submissions/:id/add_tag
  def add_tag
    tag = Tag.find(params[:tag_id])
    
    unless @submission.tags.include?(tag)
      @submission.tags << tag
      flash[:notice] = t("submissions.add_tag.success", tag: tag.tag_name)
    else
      flash[:alert] = t("submissions.add_tag.already_exists", tag: tag.tag_name)
    end
    
    # Reload tags association for turbo_stream
    @submission.tags.reload
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :add_tag }
    end
  end

  # DELETE /submissions/:id/remove_tag
  def remove_tag
    tag = Tag.find(params[:tag_id])
    
    if @submission.tags.include?(tag)
      @submission.tags.delete(tag)
      flash[:notice] = t("submissions.remove_tag.success", tag: tag.tag_name)
    else
      flash[:alert] = t("submissions.remove_tag.not_found", tag: tag.tag_name)
    end
    
    # Reload tags association for turbo_stream
    @submission.tags.reload
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :remove_tag }
    end
  end

  # POST /submissions/:id/follow
  def follow
    follow_record = current_user.follows.find_by(followable: @submission)
    
    if follow_record
      # Already following - unfollow
      follow_record.destroy
      flash[:notice] = t("submissions.follow.unfollowed")
    else
      # Not following - follow
      current_user.follows.create!(followable: @submission)
      flash[:notice] = t("submissions.follow.success")
    end
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :follow }
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition: if another request created it between find_by and create
    follow_record = current_user.follows.find_by(followable: @submission)
    follow_record&.destroy
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :follow }
    end
  end

  # POST /submissions/:id/upvote
  def upvote
    toggle_interaction_flag(:upvote, :submission_upvote)
  end

  # POST /submissions/:id/favorite
  def favorite
    toggle_interaction_flag(:favorite, :submission_favorite)
  end

  private

  def set_submission
    @submission = Submission.find(params[:id])
  end

  def authorize_owner!
    return if @submission.user == current_user

    redirect_to submissions_path, alert: t("submissions.flash.unauthorized")
  end

  def submission_params
    params.require(:submission).permit(:submission_url, :author_note)
    # Note: tool_id is no longer a parameter - tool linking is automatic via SubmissionProcessingJob
  end

  # Helper method for sorting comments (shared with ToolsController)
  def apply_sort(comments, sort_by)
    case sort_by
    when "recent"
      comments.recent
    when "most_upvoted"
      comments.most_upvoted
    when "trending"
      comments.trending
    else
      comments.recent
    end
  end

  private

  def touch_read_interaction
    return unless current_user

    user_submission = ensure_user_submission
    user_submission.read_at ||= Time.current
    user_submission.save if user_submission.changed?
  end

  def ensure_user_submission
    @user_submission ||= @submission.user_submissions.find_or_create_by(user: current_user)
  end

  def toggle_interaction_flag(flag, i18n_key)
    return redirect_to new_user_session_path unless current_user

    user_submission = ensure_user_submission
    new_value = !user_submission.public_send(flag)
    user_submission.read_at ||= Time.current
    user_submission.update(flag => new_value, read_at: user_submission.read_at)

    respond_to do |format|
      format.turbo_stream { render "submissions/interaction_update" }
      format.html { redirect_back fallback_location: submission_path(@submission), notice: t("submissions.flash.#{i18n_key}") }
    end
  end
end

