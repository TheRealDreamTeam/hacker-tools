# Base class for all notification notifiers
# All notifiers inherit from Noticed::Event (Noticed 2.0+ API)
class ApplicationNotifier < Noticed::Event
  # Database delivery is enabled by default in Noticed
  # This stores notifications in the noticed_notifications table
  
  # Action Cable delivery for real-time updates
  # Configured per-notifier, but can be overridden here for common settings
  deliver_by :action_cable do |config|
    config.channel = "Noticed::NotificationChannel"
    config.stream = -> { recipient }
    config.message = :to_websocket
  end
  
  # Common websocket message format
  # Can be overridden in individual notifiers
  def to_websocket(notification)
    {
      id: notification.id,
      type: self.class.name,
      message: notification.message,
      url: notification.url,
      created_at: notification.created_at.iso8601,
      read_at: notification.read_at&.iso8601
    }
  end
  
  # Prevent self-notifications (users shouldn't be notified about their own actions)
  # Override in individual notifiers if needed
  def self.deliver_if_not_self(recipient, actor)
    return if recipient == actor
    
    yield if block_given?
  end
end

