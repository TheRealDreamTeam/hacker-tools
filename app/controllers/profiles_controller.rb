class ProfilesController < ApplicationController
  # Profile page is only accessible to authenticated users
  # authenticate_user! is already called in ApplicationController

  # Display the user's profile page
  # Shows profile information (username, avatar, bio) and link to account settings
  def show
    @user = current_user
  end
end

