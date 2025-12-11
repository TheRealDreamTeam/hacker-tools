class ListsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_list, only: [:show, :edit, :update, :destroy, :add_tool, :remove_tool]
  
    def index
      @lists = current_user.lists
    end
  
    def show
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

      if messages.any?
        redirect_to redirect_location, notice: messages.join(". ") + "."
      else
        redirect_to redirect_location, notice: "Lists updated."
      end
    rescue ActiveRecord::RecordNotFound
      redirect_location = request.referer.present? ? request.referer : (request.path == root_path || request.path == "/" ? root_path : tool_path(tool))
      redirect_to redirect_location, alert: "Tool or list not found."
    end

    private
  
    def set_list
      @list = current_user.lists.find(params[:id])
    end
  
    def list_params
      params.require(:list).permit(:list_name, :list_type, :visibility)
    end
  end
  
