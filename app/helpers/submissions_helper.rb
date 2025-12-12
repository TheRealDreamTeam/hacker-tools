module SubmissionsHelper
  # Determine Bootstrap icon and button style for interaction buttons.
  def interaction_button_state(submission, current_user, type)
    user_submission = submission.user_submission_for(current_user)
    active =
      case type
      when :upvote then user_submission&.upvote?
      when :follow then current_user&.follows&.exists?(followable: submission)
      else false
      end

    icon_class =
      case type
      when :upvote then active ? "bi bi-arrow-up-circle-fill" : "bi bi-arrow-up-circle"
      when :follow then active ? "bi bi-bell-fill" : "bi bi-bell"
      end

    btn_class = "btn btn-sm btn-outline-secondary interaction-btn"

    {
      active: active,
      btn_class: btn_class,
      icon_class: icon_class
    }
  end
end
