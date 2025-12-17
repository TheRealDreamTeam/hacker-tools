# Background job to notify users who follow tags associated with a submission
# This runs after submission_tags associations are created
class NotifyTagFollowersJob < ApplicationJob
  queue_as :default

  def perform(submission_id)
    submission = Submission.find(submission_id)
    return if submission.user.deleted?
    
    # Get all unique users following any of the submission's tags
    tag_followers = User.joins(:follows)
                       .where(follows: { followable_type: "Tag", followable_id: submission.tags.pluck(:id) })
                       .where.not(id: submission.user_id) # Don't notify the submitter
                       .active
                       .distinct
    
    return if tag_followers.empty?
    
    # Notify each tag's followers
    submission.tags.each do |tag|
      tag_followers_for_tag = tag.followers.active.where.not(id: submission.user_id)
      next if tag_followers_for_tag.empty?
      
      NewSubmissionOnFollowedTagNotifier.with(
        record: submission,
        submission: submission,
        tag: tag,
        user: submission.user
      ).deliver_later(tag_followers_for_tag)
    end
  end
end

