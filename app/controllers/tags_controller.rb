class TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy]
  # Admin-only actions: creating, editing, and destroying tags
  before_action :require_admin!, only: %i[new create edit update destroy]

  # GET /tags
  def index
    # Group tags by type and show hierarchy
    @tags_by_type = Tag.includes(:parent, :children, :tools)
                       .order(tag_type: :asc, tag_name: :asc)
                       .group_by(&:tag_type)
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/:id
  def show
    # Tools are community-owned, no user association to include
    @tools = @tag.tools.includes(:tags).order(created_at: :desc)
  end

  # GET /tags/:id/edit
  def edit
  end

  # POST /tags
  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      redirect_to tags_path, notice: t("tags.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tags/:id
  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: t("tags.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tags/:id
  def destroy
    @tag.destroy
    redirect_to tags_path, notice: t("tags.flash.destroyed")
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:tag_name, :tag_description, :tag_type_id, :tag_type, :tag_type_slug, :parent_id, :color, :icon, :tag_alias)
  end
end

