class CommentsController < ApplicationController
  before_action :set_commentable
  before_action :set_comment, only: %i[destroy resolve upvote]
  before_action :authorize_comment_owner!, only: %i[destroy]
  before_action :authorize_commentable_owner!, only: %i[resolve]

  def create
    @comment = @commentable.comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to commentable_path(@commentable, anchor: anchor_for(@comment)), notice: t("comments.flash.created")
    else
      redirect_to commentable_path(@commentable, anchor: "discussion-section"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment.destroy
    redirect_to commentable_path(@commentable, anchor: "discussion-section"), notice: t("comments.flash.deleted")
  end

  def resolve
    @comment.update(solved: !@comment.solved)
    redirect_to commentable_path(@commentable, anchor: "discussion-section"), notice: t("comments.flash.resolved")
  end

  def upvote
    upvote_record = @comment.comment_upvotes.find_or_initialize_by(user: current_user)

    if upvote_record.persisted?
      # Already upvoted, remove upvote
      upvote_record.destroy
      redirect_to commentable_path(@commentable, anchor: anchor_for(@comment) || "discussion-section"), notice: t("comments.flash.upvote_removed")
    else
      # Not upvoted, add upvote
      upvote_record.save
      redirect_to commentable_path(@commentable, anchor: anchor_for(@comment) || "discussion-section"), notice: t("comments.flash.upvoted")
    end
  end

  private

  # Set commentable based on route params (tool_id or submission_id)
  def set_commentable
    if params[:tool_id].present?
      @commentable = Tool.find(params[:tool_id])
    elsif params[:submission_id].present?
      @commentable = Submission.find(params[:submission_id])
    else
      redirect_to root_path, alert: t("comments.flash.invalid_parent")
    end
  end

  def set_comment
    @comment = @commentable.comments.find(params[:id])
  end

  def authorize_comment_owner!
    # Allow comment owner or commentable owner to delete
    commentable_owner = @commentable.is_a?(Submission) ? @commentable.user : nil
    return if @comment.user == current_user || commentable_owner == current_user

    redirect_to commentable_path(@commentable), alert: t("comments.flash.unauthorized")
  end

  def authorize_commentable_owner!
    # Only submission owners can resolve flags/bugs (tools are community-owned)
    return if @commentable.is_a?(Submission) && @commentable.user == current_user
    return if @commentable.is_a?(Tool) # Tools are community-owned, anyone can resolve

    redirect_to commentable_path(@commentable), alert: t("comments.flash.unauthorized")
  end

  def comment_params
    params.require(:comment).permit(:comment, :parent_id, :comment_type)
  end

  def anchor_for(comment)
    return "comment-#{comment.parent_id}" if comment.parent_id.present?

    "comment-#{comment.id}"
  end

  # Helper to get the correct path for the commentable
  def commentable_path(commentable, options = {})
    case commentable
    when Tool
      tool_path(commentable, options)
    when Submission
      submission_path(commentable, options)
    else
      root_path
    end
  end
end

