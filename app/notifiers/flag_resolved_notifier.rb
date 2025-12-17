# Notifies users when a flag they created or upvoted is resolved
class FlagResolvedNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      # Return fallback message if required params are missing
      return "A flag you reported or upvoted has been resolved" unless params[:commentable]
      
      commentable_name = if params[:commentable].is_a?(Submission)
        params[:commentable].submission_name.presence || params[:commentable].submission_url
      else
        params[:commentable].tool_name
      end
      
      t(".message", commentable_name: commentable_name)
    rescue StandardError => e
      # Log error and return fallback message
      Rails.logger.error "Error generating notification message: #{e.message}"
      "A flag you reported or upvoted has been resolved"
    end
    
    def url
      # Return nil if required params are missing (e.g., commentable or flag was deleted)
      return nil unless params[:commentable] && params[:flag]
      
      if params[:commentable].is_a?(Submission)
        submission_path(id: params[:commentable].id, anchor: "flag-#{params[:flag].id}")
      else
        tool_path(id: params[:commentable].id, anchor: "flag-#{params[:flag].id}")
      end
    rescue StandardError => e
      # Log error and return nil to prevent notification rendering from failing
      Rails.logger.error "Error generating notification URL: #{e.message}"
      nil
    end
  end
end

