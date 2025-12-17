# Notifies users when their submission is rejected
class SubmissionRejectedNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      reason = params[:reason] || t(".default_reason")
      t(".message",
        submission_name: params[:submission].submission_name.presence || params[:submission].submission_url,
        reason: reason)
    end
    
    def url
      submission_path(id: params[:submission].id)
    end
  end
end

