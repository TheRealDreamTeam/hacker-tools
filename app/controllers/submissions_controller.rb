class SubmissionsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_submission, only: %i[show edit update destroy add_tag remove_tag follow]
  before_action :authorize_owner!, only: %i[edit update destroy add_tag remove_tag]

  # GET /submissions
  def index
    @submissions = Submission.includes(:user, :tool, :tags)
                             .order(created_at: :desc)
                             .page(params[:page])
    
    # Filter by submission type if provided
    @submissions = @submissions.by_type(params[:type]) if params[:type].present?
    
    # Filter by status if provided
    @submissions = @submissions.where(status: params[:status]) if params[:status].present?
    
    # Filter by tool if provided
    @submissions = @submissions.for_tool(Tool.find(params[:tool_id])) if params[:tool_id].present?
  end

  # GET /submissions/:id
  def show
    @sort_by = params[:sort_by] || "recent"
    @sort_by_flags = params[:sort_by_flags] || "recent"
    @sort_by_bugs = params[:sort_by_bugs] || "recent"

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
      # TODO: Queue processing pipeline job (Step 2.3)
      # SubmissionProcessingJob.perform_later(@submission.id)
      
      respond_to do |format|
        format.html { redirect_to @submission, notice: t("submissions.create.success") }
        format.turbo_stream { render :create }
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
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :remove_tag }
    end
  end

  # POST /submissions/:id/follow
  def follow
    follow = current_user.follows.find_or_initialize_by(followable: @submission)
    
    if follow.new_record?
      follow.save
      flash[:notice] = t("submissions.follow.success")
    else
      flash[:alert] = t("submissions.follow.already_following")
    end
    
    respond_to do |format|
      format.html { redirect_to @submission }
      format.turbo_stream { render :follow }
    end
  end

  private

  def set_submission
    @submission = Submission.find(params[:id])
  end

  def authorize_owner!
    return if @submission.user == current_user

    redirect_to @submission, alert: t("submissions.unauthorized")
  end

  def submission_params
    params.require(:submission).permit(:submission_url, :author_note, :tool_id)
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
end

