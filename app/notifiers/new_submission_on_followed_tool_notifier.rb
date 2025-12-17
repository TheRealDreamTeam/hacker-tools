# Notifies users when a new submission is created about a tool they follow
class NewSubmissionOnFollowedToolNotifier < ApplicationNotifier
# Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      t(".message",
        username: params[:user].username,
        tool_name: params[:tool].tool_name,
        submission_name: params[:submission].submission_name.presence || params[:submission].submission_url)
    end
    
    def url
      submission_path(id: params[:submission].id)
    end
  end
end

