# Notifies users when a flag they created or upvoted is resolved
class FlagResolvedNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      commentable_name = if params[:commentable].is_a?(Submission)
        params[:commentable].submission_name.presence || params[:commentable].submission_url
      else
        params[:commentable].tool_name
      end
      
      t(".message", commentable_name: commentable_name)
    end
    
    def url
      if params[:commentable].is_a?(Submission)
        submission_path(id: params[:commentable].id, anchor: "flag-#{params[:flag].id}")
      else
        tool_path(id: params[:commentable].id, anchor: "flag-#{params[:flag].id}")
      end
    end
  end
end

