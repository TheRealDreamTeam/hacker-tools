import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="confirmation-modal"
// Handles confirmation modal interactions
export default class extends Controller {
  static values = {
    confirmAction: String
  }

  connect() {
    // Listen for custom event to close modal
    document.addEventListener("turbo:close-modal", this.closeModal.bind(this))
    
    // Close modal when form inside is submitted (via Turbo)
    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', () => {
        // Close modal immediately when form is submitted
        this.close()
      })
    }
  }

  disconnect() {
    document.removeEventListener("turbo:close-modal", this.closeModal.bind(this))
  }

  // Simple close method
  close() {
    const modal = bootstrap.Modal.getInstance(this.element)
    if (modal) {
      modal.hide()
    }
  }

  closeModal(event) {
    const modalId = event.detail?.modalId
    if (modalId) {
      const modalElement = document.getElementById(modalId)
      if (modalElement) {
        const modal = bootstrap.Modal.getInstance(modalElement)
        if (modal) {
          modal.hide()
        }
      }
    }
  }

  confirm() {
    // If a confirm action URL is provided, navigate to it
    if (this.hasConfirmActionValue) {
      window.location.href = this.confirmActionValue
    }
  }
}

