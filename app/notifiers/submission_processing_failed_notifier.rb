# Notifies users when their submission processing fails
class SubmissionProcessingFailedNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      t(".message", 
        submission_name: params[:submission].submission_name.presence || params[:submission].submission_url,
        error: params[:error] || t(".default_error"))
    end
    
    def url
      submission_path(id: params[:submission].id)
    end
  end
end

