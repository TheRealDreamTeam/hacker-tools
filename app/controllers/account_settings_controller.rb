class AccountSettingsController < ApplicationController
  # Custom account settings controller - independent from Devise forms
  # Each section has its own action for independent updates

  # Show account settings page
  def show
    @user = current_user
  end

  # Update avatar only
  def update_avatar
    @user = current_user

    if @user.update(avatar_params)
      respond_to do |format|
        format.html { redirect_to account_settings_path, notice: t("account_settings.avatar.updated") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
    end
  end

  # Update bio only
  def update_bio
    @user = current_user

    if @user.update(bio_params)
      respond_to do |format|
        format.html { redirect_to account_settings_path, notice: t("account_settings.bio.updated") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
    end
  end

  # Update username and email (requires password)
  def update_username_email
    @user = current_user

    # Verify current password
    unless @user.valid_password?(params[:user][:current_password])
      @user.errors.add(:current_password, t("account_settings.username_email.invalid_password"))
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
      return
    end

    if @user.update(username_email_params)
      respond_to do |format|
        format.html { redirect_to account_settings_path, notice: t("account_settings.username_email.updated") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
    end
  end

  # Update password only (requires current password)
  def update_password
    @user = current_user

    # Verify current password
    unless @user.valid_password?(params[:user][:current_password])
      @user.errors.add(:current_password, t("account_settings.password.invalid_password"))
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
      return
    end

    if @user.update(password_params)
      # Sign in again to avoid session invalidation
      bypass_sign_in(@user)
      respond_to do |format|
        format.html { redirect_to account_settings_path, notice: t("account_settings.password.updated") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
    end
  end

  # Delete avatar
  def delete_avatar
    @user = current_user

    if @user.avatar.attached?
      @user.avatar.purge
      flash[:notice] = t("account_settings.avatar.deleted")
      respond_to do |format|
        format.html { redirect_to account_settings_path, notice: t("account_settings.avatar.deleted") }
        format.turbo_stream
      end
    else
      flash[:alert] = t("account_settings.avatar.no_avatar")
      respond_to do |format|
        format.html { redirect_to account_settings_path }
        format.turbo_stream
      end
    end
  end

  # Soft delete account (marks as deleted, anonymizes username/email, signs out)
  # Uses soft delete to preserve historical data (comments, tools) while freeing username/email for reuse
  def destroy
    @user = current_user

    # Verify password before deletion
    unless @user.valid_password?(params[:user][:password])
      # Use specific error key to avoid conflicts with password section
      @user.errors.add(:delete_account_password, t("account_settings.destroy.invalid_password"))
      flash[:alert] = t("account_settings.destroy.invalid_password")
      # Redirect back to account settings with error
      redirect_to account_settings_path, status: :see_other
      return
    end

    # Soft delete: mark as deleted and anonymize username/email
    # This preserves historical data (comments, tools) while freeing credentials for reuse
    @user.soft_delete!

    # Sign out after soft delete
    sign_out(@user)

    # Force full page redirect by using 303 See Other status
    # Since Turbo is disabled on the form, this will perform a full page reload
    redirect_to root_path, notice: t("account_settings.destroy.success"), status: :see_other
  end

  private

  def avatar_params
    params.require(:user).permit(:avatar)
  end

  def bio_params
    params.require(:user).permit(:user_bio)
  end

  def username_email_params
    params.require(:user).permit(:username, :email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end

