import { Controller } from "@hotwired/stimulus"

// Handles real-time submission form validation and processing
// Updates UI as user pastes URL and processing pipeline runs
export default class extends Controller {
  static targets = [
    "urlInput",
    "authorNoteInput",
    "submitButton",
    "statusContainer",
    "similarSubmissions",
    "processingStatus",
    "validationMessage",
    "formContainer"
  ]

  static values = {
    validateUrl: String,
    submissionId: Number
  }

  connect() {
    // Subscribe to Turbo Stream updates for this submission (if ID exists)
    if (this.submissionIdValue) {
      this.subscribeToUpdates()
    }
    
    // Debounce URL validation
    this.urlValidationTimeout = null
    
    // Disable submit button initially (until URL is entered)
    this.disableSubmit()
    
    // Check if URL is already filled (e.g., on page reload)
    if (this.urlInputTarget.value.trim().length > 0) {
      this.enableSubmit()
    }
  }

  disconnect() {
    if (this.urlValidationTimeout) {
      clearTimeout(this.urlValidationTimeout)
    }
  }

  // Called when URL input changes
  urlChanged() {
    const url = this.urlInputTarget.value.trim()
    
    // Clear previous validation
    this.clearValidation()
    
    if (url.length === 0) {
      this.disableSubmit()
      return
    }
    
    // Basic URL format check
    if (!this.isValidUrlFormat(url)) {
      this.showValidationError("Please enter a valid URL (e.g., https://example.com)")
      this.disableSubmit()
      return
    }
    
    // Debounce validation to avoid too many requests
    clearTimeout(this.urlValidationTimeout)
    this.urlValidationTimeout = setTimeout(() => {
      this.validateUrl(url)
    }, 500) // Wait 500ms after user stops typing
  }

  // Validate URL with server
  async validateUrl(url) {
    this.showProcessingStatus("Validating URL...")
    this.disableSubmit()
    
    try {
      const response = await fetch(this.validateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({ url: url })
      })
      
      const data = await response.json()
      
      if (data.duplicate) {
        this.handleDuplicate(data)
      } else if (data.similar_submissions && data.similar_submissions.length > 0) {
        this.handleSimilarSubmissions(data.similar_submissions, data.explanation)
      } else if (data.safe === false) {
        this.handleSafetyRejection(data.reason)
      } else {
        this.handleValidationSuccess()
      }
    } catch (error) {
      console.error("URL validation error:", error)
      this.showValidationError("Error validating URL. Please try again.")
      this.enableSubmit() // Allow submission even if validation fails
    }
  }

  // Handle duplicate submission
  handleDuplicate(data) {
    this.showValidationWarning(
      `This URL has already been submitted. ` +
      `<a href="${data.duplicate_path}" class="alert-link">View existing submission</a>`
    )
    this.disableSubmit()
  }

  // Handle similar submissions
  handleSimilarSubmissions(similarSubmissions, explanation) {
    this.showSimilarSubmissions(similarSubmissions, explanation)
    // Allow submission but warn user
    this.enableSubmit()
    this.showValidationWarning(
      "Similar submissions found. Please review before submitting."
    )
  }

  // Handle safety rejection
  handleSafetyRejection(reason) {
    this.showValidationError(`Content validation failed: ${reason}`)
    this.disableSubmit()
  }

  // Handle successful validation
  handleValidationSuccess() {
    this.clearValidation()
    this.enableSubmit()
    this.hideProcessingStatus()
  }

  // Show similar submissions in UI
  showSimilarSubmissions(submissions, explanation) {
    if (this.hasSimilarSubmissionsTarget) {
      this.similarSubmissionsTarget.innerHTML = this.buildSimilarSubmissionsHTML(submissions, explanation)
      this.similarSubmissionsTarget.classList.remove("d-none")
    }
  }

  // Build HTML for similar submissions
  buildSimilarSubmissionsHTML(submissions, explanation) {
    let html = '<div class="alert alert-info mb-3">'
    html += '<strong>Similar submissions found:</strong>'
    if (explanation) {
      html += `<p class="mb-2 small">${explanation}</p>`
    }
    html += '<ul class="mb-0">'
    submissions.forEach(submission => {
      html += `<li><a href="${submission.path}" target="_blank">${submission.name || submission.url}</a></li>`
    })
    html += '</ul>'
    html += '</div>'
    return html
  }

  // Show processing status
  showProcessingStatus(message) {
    if (this.hasProcessingStatusTarget) {
      this.processingStatusTarget.textContent = message
      this.processingStatusTarget.classList.remove("d-none")
    }
  }

  // Hide processing status
  hideProcessingStatus() {
    if (this.hasProcessingStatusTarget) {
      this.processingStatusTarget.classList.add("d-none")
    }
  }

  // Show validation error
  showValidationError(message) {
    if (this.hasValidationMessageTarget) {
      this.validationMessageTarget.innerHTML = `<div class="alert alert-danger">${message}</div>`
      this.validationMessageTarget.classList.remove("d-none")
    }
  }

  // Show validation warning
  showValidationWarning(message) {
    if (this.hasValidationMessageTarget) {
      this.validationMessageTarget.innerHTML = `<div class="alert alert-warning">${message}</div>`
      this.validationMessageTarget.classList.remove("d-none")
    }
  }

  // Clear validation messages
  clearValidation() {
    if (this.hasValidationMessageTarget) {
      this.validationMessageTarget.innerHTML = ""
      this.validationMessageTarget.classList.add("d-none")
    }
    if (this.hasSimilarSubmissionsTarget) {
      this.similarSubmissionsTarget.classList.add("d-none")
    }
  }

  // Enable submit button
  enableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("disabled")
    }
  }

  // Disable submit button
  disableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("disabled")
    }
  }

  // Basic URL format validation
  isValidUrlFormat(url) {
    try {
      const urlObj = new URL(url)
      return urlObj.protocol === "http:" || urlObj.protocol === "https:"
    } catch {
      return false
    }
  }

  // Subscribe to Turbo Stream updates
  subscribeToUpdates() {
    // Turbo Stream subscription is handled via turbo_stream_from in the view
    // This method can be used for additional setup if needed
  }

  // Handle Turbo Stream updates (called from Turbo Stream broadcasts)
  updateStatus(data) {
    if (data.status) {
      this.showProcessingStatus(this.getStatusMessage(data.status))
    }
    
    if (data.status === "completed") {
      this.hideProcessingStatus()
      // Redirect to submission show page
      if (data.redirect_path) {
        window.location.href = data.redirect_path
      }
    } else if (data.status === "rejected" || data.status === "failed") {
      this.showValidationError(data.message || `Submission ${data.status}`)
      this.enableSubmit() // Allow user to try again
    }
  }

  // Get human-readable status message
  getStatusMessage(status) {
    const messages = {
      processing: "Processing submission...",
      validating: "Validating content...",
      extracting: "Extracting metadata...",
      enriching: "Enriching content...",
      generating_embedding: "Generating embedding...",
      completed: "Processing complete!",
      rejected: "Submission rejected",
      failed: "Processing failed"
    }
    return messages[status] || "Processing..."
  }

  // Validate before form submission
  validateBeforeSubmit(event) {
    const url = this.urlInputTarget.value.trim()
    
    if (url.length === 0) {
      event.preventDefault()
      event.stopPropagation()
      this.showValidationError("Please enter a URL before submitting.")
      this.disableSubmit()
      return false
    }
    
    if (!this.isValidUrlFormat(url)) {
      event.preventDefault()
      event.stopPropagation()
      this.showValidationError("Please enter a valid URL (e.g., https://example.com)")
      this.disableSubmit()
      return false
    }
    
    // Allow submission to proceed
    return true
  }
}
