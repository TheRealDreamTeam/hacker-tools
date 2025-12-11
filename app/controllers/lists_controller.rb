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
    def add_tool_to_multiple
      tool = Tool.find(params[:tool_id])
      list_ids = params[:list_ids] || []
      added_count = 0

      list_ids.each do |list_id|
        list = current_user.lists.find(list_id)
        list.tools << tool unless list.tools.include?(tool)
        added_count += 1
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

      if added_count > 0
        redirect_to redirect_location, notice: "Tool added to #{added_count} list#{'s' if added_count > 1}."
      else
        redirect_to redirect_location, alert: "Please select at least one list."
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
  
