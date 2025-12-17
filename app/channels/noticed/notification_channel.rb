# Action Cable channel for real-time notification delivery
# Noticed uses this channel to broadcast notifications to users
module Noticed
  class NotificationChannel < ApplicationCable::Channel
    # Subscribe to notifications for the current user
    # Noticed uses stream_for recipient, which creates stream: "noticed::notification_channel:user_#{user.id}"
    def subscribed
      return reject_unauthorized_connection unless current_user
      
      stream_for current_user
      Rails.logger.info "User #{current_user.id} subscribed to notifications"
    end
    
    def unsubscribed
      Rails.logger.info "User #{current_user&.id} unsubscribed from notifications"
    end
    
    private
    
    # Find verified user from Warden (Devise)
    def current_user
      @current_user ||= env['warden']&.user
    end
    
    def reject_unauthorized_connection
      reject
    end
  end
end

