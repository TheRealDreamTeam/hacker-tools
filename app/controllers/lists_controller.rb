class ListsController < ApplicationController
    before_action :authenticate_user!, except: [:show]
    before_action :set_list, only: [:show]
    before_action :set_list_for_owner, only: [:edit, :update, :destroy, :add_tool, :remove_tool, :remove_submission]
    before_action :set_list_for_follow, only: [:follow, :unfollow]
  
    def index
      @lists = current_user.lists
    end
  
    def show
      # Allow viewing public lists from any user, or own lists (public or private)
      # If not signed in, only show public lists
      if user_signed_in?
        # Signed-in users can view their own lists (any visibility) or any public list
        unless @list.user == current_user || @list.visibility_public?
          redirect_to root_path, alert: t("lists.show.access_denied")
          return
        end
      else
        # Non-signed-in users can only view public lists
        unless @list.visibility_public?
          redirect_to root_path, alert: t("lists.show.access_denied")
          return
        end
      end
    end
  
    def new
      @list = current_user.lists.new
    end
  
    def create
      @list = current_user.lists.new(list_params)
      if @list.save
        redirect_to lists_path, notice: "List was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  
    def edit
    end
  
    def update
      if @list.update(list_params)
        redirect_to @list, notice: "List was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  
    def destroy
      @list.destroy
      redirect_to lists_path, notice: "List was successfully deleted."
    end

    # POST /lists/:id/add_tool
    def add_tool
      tool = Tool.find(params[:tool_id])
      @list.tools << tool unless @list.tools.include?(tool)
      redirect_back(fallback_location: @list, notice: "Tool added to list.")
    rescue ActiveRecord::RecordNotFound
      redirect_back(fallback_location: @list, alert: "Tool not found.")
    end

    # DELETE /lists/:id/remove_tool
    def remove_tool
      tool = Tool.find(params[:tool_id])
      @list.tools.delete(tool)
      redirect_back(fallback_location: @list, notice: "Tool removed from list.")
    rescue ActiveRecord::RecordNotFound
      redirect_back(fallback_location: @list, alert: "Tool not found.")
    end

    # DELETE /lists/:id/remove_submission
    def remove_submission
      submission = Submission.find(params[:submission_id])
      @list.submissions.delete(submission)
      redirect_back(fallback_location: @list, notice: "Submission removed from list.")
    rescue ActiveRecord::RecordNotFound
      redirect_back(fallback_location: @list, alert: "Submission not found.")
    end

    # POST /lists/:id/follow
    # Follow a list (toggle: follow if not following, unfollow if already following)
    def follow
      # Prevent following own lists
      if current_user == @list.user
        redirect_to list_path(@list), alert: t("lists.follow.cannot_follow_own")
        return
      end

      # Toggle follow: if exists, destroy (unfollow); if not, create (follow)
      follow_record = current_user.follows.find_by(followable: @list)
      
      if follow_record
        # Already following - unfollow
        follow_record.destroy
        message = t("lists.follow.unfollowed", list_name: @list.list_name)
      else
        # Not following - follow (use find_or_create_by to handle race conditions)
        begin
          current_user.follows.find_or_create_by!(followable: @list)
          message = t("lists.follow.followed", list_name: @list.list_name)
        rescue ActiveRecord::RecordInvalid => e
          # Handle validation error (e.g., own list follow attempt)
          redirect_to list_path(@list), alert: e.message
          return
        end
      end

      # Reload list and clear association cache to get updated follower count
      @list.reload
      @list.association(:followers).reset
      
      # Refresh follow state for current user (clear association cache)
      current_user.association(:follows).reset if current_user.follows.loaded?

      respond_to do |format|
        format.turbo_stream { render "lists/follow_update" }
        format.html { redirect_to list_path(@list), notice: message }
      end
    rescue ActiveRecord::RecordNotUnique
      # Handle race condition: if another request created it between find and create
      # The follow now exists, so destroy it (toggle behavior)
      follow_record = current_user.follows.find_by(followable: @list)
      follow_record&.destroy
      @list.reload
      @list.association(:followers).reset

      respond_to do |format|
        format.turbo_stream { render "lists/follow_update" }
        format.html { redirect_to list_path(@list), notice: t("lists.follow.unfollowed", list_name: @list.list_name) }
      end
    end

    # DELETE /lists/:id/unfollow
    # Unfollow a list (alternative to toggle in follow action)
    def unfollow
      follow_record = current_user.follows.find_by(followable: @list)
      follow_record&.destroy
      
      # Reload list and clear association cache to get updated follower count
      @list.reload
      @list.association(:followers).reset
      
      # Refresh follow state for current user (clear association cache)
      current_user.association(:follows).reset if current_user.follows.loaded?

      respond_to do |format|
        format.turbo_stream { render "lists/follow_update" }
        format.html { redirect_to list_path(@list), notice: t("lists.follow.unfollowed", list_name: @list.list_name) }
      end
    end

    # POST /lists/add_tool_to_multiple
    # Updates tool membership across multiple lists - adds to checked lists, removes from unchecked lists
    def add_tool_to_multiple
      tool = Tool.find(params[:tool_id])
      submitted_list_ids = (params[:list_ids] || []).map(&:to_i)
      user_lists = current_user.lists.includes(:tools)
      
      added_count = 0
      removed_count = 0

      # Process each of the user's lists
      user_lists.each do |list|
        has_tool = list.tools.include?(tool)
        should_have_tool = submitted_list_ids.include?(list.id)

        if should_have_tool && !has_tool
          # Add tool to list
          list.tools << tool
          added_count += 1
        elsif !should_have_tool && has_tool
          # Remove tool from list
          list.tools.delete(tool)
          removed_count += 1
        end
      end

      # Determine redirect location - prefer referer if available, otherwise use root or tool path
      # This ensures redirect works correctly even on root page
      redirect_location = if request.referer.present? && URI(request.referer).path != request.path
                            request.referer
                          elsif request.path == root_path || request.path == "/"
                            root_path
                          else
                            tool_path(tool)
                          end

      # Build appropriate success message
      messages = []
      messages << "Added to #{added_count} list#{'s' if added_count != 1}" if added_count > 0
      messages << "Removed from #{removed_count} list#{'s' if removed_count != 1}" if removed_count > 0

      notice_message = if messages.any?
                         messages.join(". ") + "."
                       else
                         "Lists updated."
                       end

      # Reload tool associations to get updated list count
      tool.reload
      # Clear association cache to ensure fresh count
      tool.association(:lists).reset if tool.association(:lists).loaded?

      respond_to do |format|
        format.html { redirect_to redirect_location, notice: notice_message }
        format.turbo_stream { 
          @tool = tool
          flash.now[:notice] = notice_message
          render "lists/add_tool_to_multiple"
        }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_location = request.referer.present? ? request.referer : (request.path == root_path || request.path == "/" ? root_path : tool_path(tool))
      respond_to do |format|
        format.html { redirect_to redirect_location, alert: "Tool or list not found." }
        format.turbo_stream {
          flash.now[:alert] = "Tool or list not found."
          render "lists/add_tool_to_multiple"
        }
      end
    end

    # POST /lists/add_submission_to_multiple
    # Updates submission membership across multiple lists - adds to checked lists, removes from unchecked lists
    def add_submission_to_multiple
      submission = Submission.find(params[:submission_id])
      submitted_list_ids = (params[:list_ids] || []).map(&:to_i)
      user_lists = current_user.lists.includes(:submissions)
      
      added_count = 0
      removed_count = 0

      # Process each of the user's lists
      user_lists.each do |list|
        has_submission = list.submissions.include?(submission)
        should_have_submission = submitted_list_ids.include?(list.id)

        if should_have_submission && !has_submission
          # Add submission to list
          list.submissions << submission
          added_count += 1
        elsif !should_have_submission && has_submission
          # Remove submission from list
          list.submissions.delete(submission)
          removed_count += 1
        end
      end

      # Determine redirect location - prefer referer if available, otherwise use root or submission path
      # This ensures redirect works correctly even on root page
      redirect_location = if request.referer.present? && URI(request.referer).path != request.path
                            request.referer
                          elsif request.path == root_path || request.path == "/"
                            root_path
                          else
                            submission_path(submission)
                          end

      # Build appropriate success message
      messages = []
      messages << "Added to #{added_count} list#{'s' if added_count != 1}" if added_count > 0
      messages << "Removed from #{removed_count} list#{'s' if removed_count != 1}" if removed_count > 0

      notice_message = if messages.any?
                         messages.join(". ") + "."
                       else
                         "Lists updated."
                       end

      # Reload submission associations to get updated list count
      submission.reload
      # Clear association cache to ensure fresh count
      submission.association(:lists).reset if submission.association(:lists).loaded?

      respond_to do |format|
        format.html { redirect_to redirect_location, notice: notice_message }
        format.turbo_stream { 
          @submission = submission
          flash.now[:notice] = notice_message
          render "lists/add_submission_to_multiple"
        }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_location = request.referer.present? ? request.referer : (request.path == root_path || request.path == "/" ? root_path : submission_path(submission))
      respond_to do |format|
        format.html { redirect_to redirect_location, alert: "Submission or list not found." }
        format.turbo_stream {
          flash.now[:alert] = "Submission or list not found."
          render "lists/add_submission_to_multiple"
        }
      end
    end

    private
  
    # Set list for show action - allows viewing public lists from any user
    # or own lists (any visibility)
    def set_list
      @list = List.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t("lists.show.not_found")
    end

    # Set list for owner-only actions (edit, update, destroy, add_tool, remove_tool)
    # Only allows access to lists owned by the current user
    def set_list_for_owner
      @list = current_user.lists.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t("lists.show.not_found")
    end

    # Set list for follow/unfollow actions - allows finding any public list
    # This is separate from set_list because follow/unfollow should work on any public list,
    # not just lists owned by the current user
    def set_list_for_follow
      @list = List.public_lists.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t("lists.follow.list_not_found")
    end
  
    def list_params
      permitted = params.require(:list).permit(:list_name, :list_type, :visibility)
      # Convert visibility enum key string to integer for database storage
      # Forms submit enum keys ("private", "public") but database stores integers (0, 1)
      if permitted[:visibility].present?
        # If it's already an integer, use it; otherwise convert enum key to integer
        if permitted[:visibility].is_a?(String) && permitted[:visibility].match?(/\A\d+\z/)
          permitted[:visibility] = permitted[:visibility].to_i
        elsif permitted[:visibility].is_a?(String)
          # Convert enum key ("private", "public") to integer using the enum mapping
          permitted[:visibility] = List.visibilities[permitted[:visibility]]
        end
      end
      permitted
    end
  end
  
