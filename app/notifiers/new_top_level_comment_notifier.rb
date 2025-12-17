# Notifies submission/tool owners when a new top-level comment is created
class NewTopLevelCommentNotifier < ApplicationNotifier
  # Database and Action Cable delivery are configured in ApplicationNotifier
  
  notification_methods do
    def message
      commentable_name = if params[:commentable].is_a?(Submission)
        params[:commentable].submission_name.presence || params[:commentable].submission_url
      else
        params[:commentable].tool_name
      end
      
      t(".message",
        username: params[:user].username,
        commentable_name: commentable_name)
    end
    
    def url
      if params[:commentable].is_a?(Submission)
        submission_path(id: params[:commentable].id, anchor: "comment-#{params[:comment].id}")
      else
        tool_path(id: params[:commentable].id, anchor: "comment-#{params[:comment].id}")
      end
    end
  end
end

