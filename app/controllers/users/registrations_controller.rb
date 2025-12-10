class Users::RegistrationsController < Devise::RegistrationsController
  # Override create to ensure redirect uses HTML format after sign up
  # This prevents TURBO_STREAM format from being preserved on redirect
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        # Force full page redirect by using 303 See Other status and setting Turbo header
        # This ensures Turbo performs a full page load instead of preserving format
        response.headers["Turbo-Location"] = after_sign_up_path_for(resource)
        redirect_to after_sign_up_path_for(resource), status: :see_other
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        # Force full page redirect by using 303 See Other status and setting Turbo header
        # This ensures Turbo performs a full page load instead of preserving format
        response.headers["Turbo-Location"] = after_inactive_sign_up_path_for(resource)
        redirect_to after_inactive_sign_up_path_for(resource), status: :see_other
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # Override Devise's update action to allow avatar and bio updates without password
  # For security, password is still required for username, email, and password changes

  def update
    # Check if this is an avatar or bio-only update (no password required)
    skip_password_type = params[:user]&.dig(:skip_password_validation)
    update_section = params[:user]&.dig(:update_section)

    # If this is an avatar or bio update, we can skip password validation
    if skip_password_type.present? && (skip_password_type == "avatar" || skip_password_type == "bio")
      # Get all permitted params and filter to only allow specific fields
      # We include username and email to satisfy model validations
      if skip_password_type == "avatar"
        # Only allow avatar, username, and email
        permitted_params = params.require(:user).permit(:username, :email, :avatar)
      elsif skip_password_type == "bio"
        # Only allow user_bio, username, and email
        permitted_params = params.require(:user).permit(:username, :email, :user_bio)
      end

      # Update without password requirement
      if resource.update_without_password(permitted_params)
        set_flash_message! :notice, :updated
        # Render in-place instead of redirecting
        respond_to do |format|
          format.html { render :edit, status: :ok }
          format.turbo_stream { render :edit, status: :ok }
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    elsif update_section == "username_email"
      # Username and email update - require password
      # Only allow username and email updates
      permitted_params = params.require(:user).permit(:username, :email, :current_password)
      
      if resource.update_with_password(permitted_params)
        set_flash_message! :notice, :updated
        # Render in-place instead of redirecting
        respond_to do |format|
          format.html { render :edit, status: :ok }
          format.turbo_stream { render :edit, status: :ok }
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    elsif update_section == "password"
      # Password update - require current password
      # Only allow password updates
      permitted_params = params.require(:user).permit(:password, :password_confirmation, :current_password, :username, :email)
      
      if resource.update_with_password(permitted_params)
        set_flash_message! :notice, :updated
        # Render in-place instead of redirecting
        respond_to do |format|
          format.html { render :edit, status: :ok }
          format.turbo_stream { render :edit, status: :ok }
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      # For other account updates, use default Devise behavior
      super
    end
  end

  # Delete avatar action
  # Use current_user since resource may not be set up for custom actions
  def delete_avatar
    user = current_user
    
    if user.avatar.attached?
      user.avatar.purge
      flash[:notice] = t("devise.registrations.edit.avatar_deleted")
      # Render in-place instead of redirecting
      # Need to set resource for the view
      self.resource = user
      respond_to do |format|
        format.html { render :edit, status: :ok }
        format.turbo_stream { render :edit, status: :ok }
      end
    else
      flash[:alert] = t("devise.registrations.edit.no_avatar_to_delete")
      # Need to set resource for the view
      self.resource = user
      respond_to do |format|
        format.html { render :edit, status: :ok }
        format.turbo_stream { render :edit, status: :ok }
      end
    end
  end

  # Override destroy to ensure account deletion redirects to homepage and signs out
  # This is the only action that should redirect (all others render in-place)
  def destroy
    # Use Devise's default destroy which handles sign out and redirect
    super
  end

  private

  # Override to allow updates without password for avatar/bio
  def account_update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end
end

