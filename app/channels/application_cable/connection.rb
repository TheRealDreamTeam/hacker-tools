module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}" if current_user
    end

    private

    # Find verified user from Warden (Devise)
    # This allows Action Cable to identify the current user for notification streams
    def find_verified_user
      if current_user = env['warden']&.user
        current_user
      else
        reject_unauthorized_connection
      end
    end

    def reject_unauthorized_connection
      reject
    end
  end
end

