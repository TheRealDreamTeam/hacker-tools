import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-to-list-button"
// This controller is attached to buttons that trigger the add-to-list modal
// It dispatches a custom event that the modal controller listens for
// Supports both tools and submissions
export default class extends Controller {
  static values = {
    toolId: Number,
    toolName: String,
    submissionId: Number,
    submissionName: String,
    lists: Array
  }

  open(event) {
    event.preventDefault()
    
    // Determine if this is a tool or submission based on which values are present
    const isSubmission = this.hasSubmissionIdValue && this.hasSubmissionNameValue
    const isTool = this.hasToolIdValue && this.hasToolNameValue
    
    if (isSubmission) {
      // Dispatch custom event with submission data
      document.dispatchEvent(new CustomEvent("add-to-list-modal:open", {
        detail: {
          type: "submission",
          submissionId: this.submissionIdValue,
          submissionName: this.submissionNameValue,
          lists: this.listsValue
        }
      }))
    } else if (isTool) {
      // Dispatch custom event with tool data
      document.dispatchEvent(new CustomEvent("add-to-list-modal:open", {
        detail: {
          type: "tool",
          toolId: this.toolIdValue,
          toolName: this.toolNameValue,
          lists: this.listsValue
        }
      }))
    } else {
      console.error("Add to list button: Missing required values (toolId/toolName or submissionId/submissionName)")
    }
  }
}
