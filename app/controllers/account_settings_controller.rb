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

  # Delete account (redirects and signs out)
  def destroy
    @user = current_user

    # Verify password before deletion
    unless @user.valid_password?(params[:user][:password])
      @user.errors.add(:password, t("account_settings.destroy.invalid_password"))
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.turbo_stream { render :show, status: :unprocessable_entity }
      end
      return
    end

    # Sign out before destroying
    sign_out(@user)
    @user.destroy

    redirect_to root_path, notice: t("account_settings.destroy.success")
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

