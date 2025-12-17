# Notifies submission/tool owners when a new top-level comment is created
class NewTopLevelCommentNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      # Return fallback message if required params are missing
      return "Someone commented" unless params[:commentable] && params[:user]
      
      commentable_name = if params[:commentable].is_a?(Submission)
        params[:commentable].submission_name.presence || params[:commentable].submission_url
      else
        params[:commentable].tool_name
      end
      
      t(".message",
        username: params[:user].username,
        commentable_name: commentable_name)
    rescue StandardError => e
      # Log error and return fallback message
      Rails.logger.error "Error generating notification message: #{e.message}"
      "Someone commented"
    end
    
    def url
      # Return nil if required params are missing (e.g., commentable or comment was deleted)
      return nil unless params[:commentable] && params[:comment]
      
      if params[:commentable].is_a?(Submission)
        submission_path(id: params[:commentable].id, anchor: "comment-#{params[:comment].id}")
      else
        tool_path(id: params[:commentable].id, anchor: "comment-#{params[:comment].id}")
      end
    rescue StandardError => e
      # Log error and return nil to prevent notification rendering from failing
      Rails.logger.error "Error generating notification URL: #{e.message}"
      nil
    end
  end
end

