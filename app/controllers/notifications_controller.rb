class NotificationsController < ApplicationController
  before_action :authenticate_user!
  
  # GET /notifications
  def index
    @notifications = current_user.notifications
                                 .includes(:event)
                                 .order(created_at: :desc)
                                 .limit(50)
    
    # Mark notifications as seen when viewing the index
    current_user.notifications.where(seen_at: nil).update_all(seen_at: Time.current)
  end
  
  # PATCH /notifications/:id/mark_as_read
  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path, notice: t("notifications.marked_as_read") }
    end
  end
  
  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.where(read_at: nil).update_all(read_at: Time.current)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path, notice: t("notifications.all_marked_as_read") }
    end
  end
end

