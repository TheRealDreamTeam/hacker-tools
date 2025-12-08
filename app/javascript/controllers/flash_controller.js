import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    autoDismiss: Number
  }

  connect() {
    // Auto-dismiss after specified milliseconds (default 2000ms)
    if (this.hasAutoDismissValue && this.autoDismissValue > 0) {
      setTimeout(() => {
        this.dismiss()
      }, this.autoDismissValue)
    }
  }

  dismiss() {
    // Add fade-out class for animation
    this.element.classList.add("fade-out")
    
    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 300) // Match animation duration
  }
}

