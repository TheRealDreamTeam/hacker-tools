import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-to-list-button"
// This controller is attached to buttons that trigger the add-to-list modal
// It dispatches a custom event that the modal controller listens for
export default class extends Controller {
  static values = {
    toolId: Number,
    toolName: String,
    lists: Array
  }

  open(event) {
    event.preventDefault()
    
    // Dispatch custom event with tool data
    // The modal controller (attached to the modal element) will listen for this event
    document.dispatchEvent(new CustomEvent("add-to-list-modal:open", {
      detail: {
        toolId: this.toolIdValue,
        toolName: this.toolNameValue,
        lists: this.listsValue
      }
    }))
  }
}
