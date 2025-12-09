class ToolsController < ApplicationController
  before_action :set_tool, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]

  # GET /tools
  def index
    @tools = Tool.includes(:user).order(created_at: :desc)
  end

  # GET /tools/:id
  def show
  end

  # GET /tools/new
  def new
    @tool = current_user.tools.new
  end

  # GET /tools/:id/edit
  def edit
  end

  # POST /tools
  def create
    @tool = current_user.tools.new(tool_params)

    if @tool.save
      redirect_to @tool, notice: t("tools.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tools/:id
  def update
    if @tool.update(tool_params)
      redirect_to @tool, notice: t("tools.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tools/:id
  def destroy
    @tool.destroy
    redirect_to tools_path, notice: t("tools.flash.destroyed")
  end

  private

  def set_tool
    @tool = Tool.find(params[:id])
  end

  # Ensure only the owner can modify or delete.
  def authorize_owner!
    return if @tool.user == current_user

    redirect_to tools_path, alert: t("tools.flash.unauthorized")
  end

  def tool_params
    params.require(:tool).permit(:tool_url, :author_note)
  end
end

