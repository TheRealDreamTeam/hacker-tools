import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="delete-account-modal"
// Handles delete account modal interactions
// Keeps modal open when there are validation errors
export default class extends Controller {
  connect() {
    // Get the modal instance
    this.modal = bootstrap.Modal.getInstance(this.element)
    
    // If modal doesn't exist yet, create it
    if (!this.modal) {
      this.modal = new bootstrap.Modal(this.element)
    }
    
    // Listen for Turbo Stream responses
    // Only close modal on successful deletion (redirect), not on validation errors
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmitEnd(event) {
    // If the form submission resulted in a redirect (success), the modal will be closed
    // by the page navigation. If it's a Turbo Stream response with errors (status 422),
    // keep the modal open so user can correct the password.
    // Turbo Streams will update the modal content with error messages.
    
    const response = event.detail.fetchResponse
    
    // If response is unprocessable_entity (422), it means validation failed
    // Keep modal open and let Turbo Streams update the content
    if (response.status === 422) {
      // Ensure modal stays open - Turbo Streams will update the content
      // The modal instance should remain intact after content replacement
      if (this.modal && !this.modal._isShown) {
        // Modal was closed somehow, reopen it
        this.modal.show()
      }
    }
    // For successful deletion (redirect), modal will close automatically on navigation
  }
}
