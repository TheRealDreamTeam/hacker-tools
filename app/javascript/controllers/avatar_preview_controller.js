import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="avatar-preview"
// Handles avatar file selection preview and enables/disables submit button
export default class extends Controller {
  static targets = ["preview", "fileInput", "submitButton", "placeholder"]

  connect() {
    // Submit button should only be enabled when a new file is selected
    // Even if avatar exists, user must select a new file to update
    if (this.hasSubmitButtonTarget) {
      // Check if file input has a file selected
      const hasFileSelected = this.hasFileInputTarget && this.fileInputTarget.files.length > 0
      
      // Enable button only if a new file is selected
      this.submitButtonTarget.disabled = !hasFileSelected
    }
  }

  // When file is selected, show preview and enable submit button
  fileSelected(event) {
    const file = event.target.files[0]
    
    if (file && file.type.startsWith("image/")) {
      // Create preview
      const reader = new FileReader()
      reader.onload = (e) => {
        const previewContainer = this.element.querySelector("#avatar-preview-container")
        
        // Hide placeholder if it exists
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.style.display = "none"
        }
        
        // Show or update preview image
        if (this.hasPreviewTarget) {
          // Update existing preview image
          this.previewTarget.src = e.target.result
          this.previewTarget.style.display = "block"
        } else {
          // Create preview element if it doesn't exist
          const preview = document.createElement("img")
          preview.src = e.target.result
          preview.className = "rounded"
          preview.style.cssText = "height: 100px; width: 100px; object-fit: cover; display: block;"
          preview.setAttribute("data-avatar-preview-target", "preview")
          
          // Replace placeholder or append to container
          if (previewContainer) {
            const placeholder = previewContainer.querySelector('[data-avatar-preview-target="placeholder"]')
            if (placeholder) {
              placeholder.replaceWith(preview)
            } else {
              previewContainer.appendChild(preview)
            }
          }
        }
      }
      reader.readAsDataURL(file)
      
      // Enable submit button
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
      }
    } else {
      // Disable submit button if invalid file
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = true
      }
    }
  }
}

