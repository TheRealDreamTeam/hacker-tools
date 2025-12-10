class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # Set locale from params, user preference, or default
  # Locale can be set via ?locale=en in URL params
  # Can be extended to read from user preferences, session, or Accept-Language header
  def set_locale
    # Check if locale is provided in params and is available
    if params[:locale].present? && I18n.available_locales.map(&:to_s).include?(params[:locale])
      I18n.locale = params[:locale]
    else
      # Use default locale (configured in config/application.rb)
      I18n.locale = I18n.default_locale
    end
  end

  # Include locale in URL params for all generated URLs
  # This ensures locale persists across navigation
  def default_url_options
    { locale: I18n.locale }
  end

  # Permit additional Devise parameters such as username to satisfy DB null constraints.
  # Avatar and user_bio are optional and only permitted on account_update (not sign_up)
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :avatar, :user_bio])
  end
end
