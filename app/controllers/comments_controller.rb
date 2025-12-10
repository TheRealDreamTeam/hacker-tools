class CommentsController < ApplicationController
  before_action :set_tool
  before_action :set_comment, only: %i[destroy resolve upvote]
  before_action :authorize_comment_owner!, only: %i[destroy]
  before_action :authorize_tool_owner!, only: %i[resolve]

  def create
    @comment = @tool.comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to tool_path(@tool, anchor: anchor_for(@comment)), notice: t("comments.flash.created")
    else
      redirect_to tool_path(@tool), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment.destroy
    redirect_to tool_path(@tool), notice: t("comments.flash.deleted")
  end

  def resolve
    @comment.update(solved: !@comment.solved)
    redirect_to tool_path(@tool), notice: t("comments.flash.resolved")
  end

  def upvote
    upvote_record = @comment.comment_upvotes.find_or_initialize_by(user: current_user)

    if upvote_record.persisted?
      # Already upvoted, remove upvote
      upvote_record.destroy
      redirect_to tool_path(@tool, anchor: anchor_for(@comment)), notice: t("comments.flash.upvote_removed")
    else
      # Not upvoted, add upvote
      upvote_record.save
      redirect_to tool_path(@tool, anchor: anchor_for(@comment)), notice: t("comments.flash.upvoted")
    end
  end

  private

  def set_tool
    @tool = Tool.find(params[:tool_id])
  end

  def set_comment
    @comment = @tool.comments.find(params[:id])
  end

  def authorize_comment_owner!
    return if @comment.user == current_user || @tool.user == current_user

    redirect_to tool_path(@tool), alert: t("comments.flash.unauthorized")
  end

  def authorize_tool_owner!
    return if @tool.user == current_user

    redirect_to tool_path(@tool), alert: t("comments.flash.unauthorized")
  end

  def comment_params
    params.require(:comment).permit(:comment, :parent_id, :comment_type)
  end

  def anchor_for(comment)
    return "comment-#{comment.parent_id}" if comment.parent_id.present?

    "comment-#{comment.id}"
  end
end

