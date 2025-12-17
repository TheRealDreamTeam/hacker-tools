class ErrorsController < ApplicationController
  # Error pages must be publicly accessible and should not trigger auth or cache headers.
  skip_before_action :authenticate_user!
  skip_before_action :set_no_cache_for_authenticated_pages
  skip_before_action :set_locale

  layout "application"

  def not_found
    render :not_found, status: :not_found
  end

  def internal_server_error
    render :internal_server_error, status: :internal_server_error
  end

  private

  # Avoid appending locale query params to keep error URLs clean.
  def default_url_options
    {}
  end
end

