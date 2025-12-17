# Notifies users when a user they follow creates a new submission
class NewSubmissionFromFollowedUserNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  # Helper methods accessible in notifications
  notification_methods do
    def message
      t(".message", 
        username: params[:user].username, 
        submission_name: params[:submission].submission_name.presence || params[:submission].submission_url)
    end
    
    def url
      submission_path(id: params[:submission].id)
    end
  end
end

