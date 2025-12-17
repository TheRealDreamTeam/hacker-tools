# Notifies users when a bug they reported or upvoted is resolved
class BugResolvedNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      # Return fallback message if required params are missing
      return "A bug you reported or upvoted has been resolved" unless params[:commentable]
      
      commentable_name = if params[:commentable].is_a?(Submission)
        params[:commentable].submission_name.presence || params[:commentable].submission_url
      else
        params[:commentable].tool_name
      end
      
      t(".message", commentable_name: commentable_name)
    rescue StandardError => e
      # Log error and return fallback message
      Rails.logger.error "Error generating notification message: #{e.message}"
      "A bug you reported or upvoted has been resolved"
    end
    
    def url
      # Return nil if required params are missing (e.g., commentable or bug was deleted)
      return nil unless params[:commentable] && params[:bug]
      
      if params[:commentable].is_a?(Submission)
        submission_path(id: params[:commentable].id, anchor: "bug-#{params[:bug].id}")
      else
        tool_path(id: params[:commentable].id, anchor: "bug-#{params[:bug].id}")
      end
    rescue StandardError => e
      # Log error and return nil to prevent notification rendering from failing
      Rails.logger.error "Error generating notification URL: #{e.message}"
      nil
    end
  end
end

