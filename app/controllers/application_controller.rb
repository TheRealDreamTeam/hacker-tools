class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale

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
end
