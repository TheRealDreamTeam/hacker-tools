// Simple implementation of eagerLoadControllersFrom for importmap
// Manually imports and registers all Stimulus controllers
// This works with importmap's static import system

export function eagerLoadControllersFrom(controllersPath, application) {
  // Import all controllers statically - importmap requires static imports
  // These will be loaded eagerly when this module is imported
  import("controllers/add_to_list_button_controller").then(m => m.default && application.register("add-to-list-button", m.default))
  import("controllers/add_to_list_modal_controller").then(m => m.default && application.register("add-to-list-modal", m.default))
  import("controllers/avatar_preview_controller").then(m => m.default && application.register("avatar-preview", m.default))
  import("controllers/bio_form_controller").then(m => m.default && application.register("bio-form", m.default))
  import("controllers/confirmation_modal_controller").then(m => m.default && application.register("confirmation-modal", m.default))
  import("controllers/delete_account_modal_controller").then(m => m.default && application.register("delete-account-modal", m.default))
  import("controllers/flash_controller").then(m => m.default && application.register("flash", m.default))
  import("controllers/hello_controller").then(m => m.default && application.register("hello", m.default))
  import("controllers/home_page_controller").then(m => m.default && application.register("home-page", m.default))
  import("controllers/navbar_offcanvas_controller").then(m => m.default && application.register("navbar-offcanvas", m.default))
  import("controllers/notifications_controller").then(m => m.default && application.register("notifications", m.default))
  import("controllers/page_transition_controller").then(m => m.default && application.register("page-transition", m.default))
  import("controllers/search_filters_controller").then(m => m.default && application.register("search-filters", m.default))
  import("controllers/search_suggestions_controller").then(m => m.default && application.register("search-suggestions", m.default))
  import("controllers/submission_form_controller").then(m => m.default && application.register("submission-form", m.default))
  import("controllers/tag_form_controller").then(m => m.default && application.register("tag-form", m.default))
  import("controllers/tool_card_controller").then(m => m.default && application.register("tool-card", m.default))
  import("controllers/tooltip_controller").then(m => m.default && application.register("tooltip", m.default))
  import("controllers/visibility_toggle_controller").then(m => {
    console.log("Visibility toggle: Controller module loaded", m)
    if (m.default) {
      application.register("visibility-toggle", m.default)
      console.log("Visibility toggle: Controller registered successfully")
    } else {
      console.error("Visibility toggle: Controller module has no default export", m)
    }
  }).catch(e => {
    console.error("Failed to load visibility-toggle controller:", e)
    console.error("Error stack:", e.stack)
  })
  import("controllers/inline_edit_controller").then(m => m.default && application.register("inline-edit", m.default)).catch(e => console.error("Failed to load inline-edit controller:", e))
  import("controllers/wave_text_controller").then(m => m.default && application.register("wave-text", m.default))
}
