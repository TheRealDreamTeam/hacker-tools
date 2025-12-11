module ToolsHelper
  # Determine Bootstrap icon and button style for interaction buttons.
  def interaction_button_state(tool, current_user, type)
    user_tool = tool.user_tool_for(current_user)
    active =
      case type
      when :upvote then user_tool&.upvote?
      when :favorite then user_tool&.favorite?
      when :follow then current_user&.follows&.exists?(followable: tool)
      else false
      end

    icon_class =
      case type
      when :upvote then active ? "bi bi-arrow-up-circle-fill" : "bi bi-arrow-up-circle"
      when :favorite then active ? "bi bi-star-fill" : "bi bi-star"
      when :follow then active ? "bi bi-bell-fill" : "bi bi-bell"
      end

    btn_class = "btn btn-sm btn-outline-secondary interaction-btn"

    {
      active: active,
      btn_class: btn_class,
      icon_class: icon_class
    }
  end

  def read_state(tool, current_user)
    ut = tool.user_tool_for(current_user)
    visited = ut&.read_at.present?
    {
      visited: visited,
      icon_class: visited ? "bi bi-eye-fill text-success" : "bi bi-eye text-secondary",
      title: visited ? t("tools.read.visited") : t("tools.read.not_visited"),
      read_at: ut&.read_at
    }
  end
end

