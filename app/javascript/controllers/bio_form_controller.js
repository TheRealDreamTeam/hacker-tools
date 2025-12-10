import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bio-form"
// Enables/disables submit button based on bio textarea changes
export default class extends Controller {
  static targets = ["textarea", "submitButton"]
  static values = { originalValue: String }

  connect() {
    // Store original value
    if (this.hasTextareaTarget) {
      this.originalValueValue = this.textareaTarget.value || ""
      // Initially disable submit button (value hasn't changed yet)
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = true
      }
    }
  }

  // When textarea value changes, check if it's different from original
  // Called via Stimulus action: data-action="input->bio-form#valueChanged"
  valueChanged() {
    if (this.hasTextareaTarget && this.hasSubmitButtonTarget) {
      const currentValue = this.textareaTarget.value || ""
      // Enable button only if value has changed
      this.submitButtonTarget.disabled = (currentValue === this.originalValueValue)
    }
  }
}

