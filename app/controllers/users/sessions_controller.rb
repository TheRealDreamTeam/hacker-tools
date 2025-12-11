class Users::SessionsController < Devise::SessionsController
  # Override create to ensure redirect uses HTML format after sign in
  # This prevents TURBO_STREAM format from being preserved on redirect
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    # Force full page redirect by using 303 See Other status and setting Turbo header
    # This ensures Turbo performs a full page load instead of preserving format
    response.headers["Turbo-Location"] = after_sign_in_path_for(resource)
    redirect_to after_sign_in_path_for(resource), status: :see_other
  end

  # Override destroy to ensure redirect uses HTML format after sign out
  # This prevents TURBO_STREAM format from being preserved on redirect
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    # Explicitly handle both formats to force HTML redirect
    respond_to do |format|
      format.html { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
      format.turbo_stream { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
    end
  end
end

