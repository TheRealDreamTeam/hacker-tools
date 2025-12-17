# Background job to notify users who follow tools associated with a submission
# This runs after submission_tools associations are created
class NotifyToolFollowersJob < ApplicationJob
  queue_as :default

  def perform(submission_id)
    submission = Submission.find(submission_id)
    return if submission.user.deleted?
    
    # Get all unique users following any of the submission's tools
    tool_followers = User.joins(:follows)
                        .where(follows: { followable_type: "Tool", followable_id: submission.tools.pluck(:id) })
                        .where.not(id: submission.user_id) # Don't notify the submitter
                        .active
                        .distinct
    
    return if tool_followers.empty?
    
    # Notify each tool's followers
    submission.tools.each do |tool|
      tool_followers_for_tool = tool.followers.active.where.not(id: submission.user_id)
      next if tool_followers_for_tool.empty?
      
      NewSubmissionOnFollowedToolNotifier.with(
        record: submission,
        submission: submission,
        tool: tool,
        user: submission.user
      ).deliver_later(tool_followers_for_tool)
    end
  end
end

