import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="inline-edit"
// Manages inline editing of list names - toggles between display (h1) and input field
export default class extends Controller {
  static targets = ["display", "displayContainer", "input", "form", "formElement", "editButton", "confirmButton", "cancelButton"]
  static values = { 
    url: String,
    field: String
  }

  connect() {
    // Ensure form is hidden initially and display is visible
    // Use Bootstrap's d-none class for hiding
    this.hideForm()
    this.showDisplay()
  }

  edit() {
    // Hide display and edit button, show form
    this.hideDisplay()
    this.showForm()
  }

  cancel(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Reset input value to original display value
    if (this.hasInputTarget && this.hasDisplayTarget) {
      this.inputTarget.value = this.displayTarget.textContent.trim()
    }
    
    // Hide form, show display
    this.hideForm()
    this.showDisplay()
  }

  save(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.hasFormElementTarget || !this.hasInputTarget) return

    const formData = new FormData(this.formElementTarget)
    const value = formData.get(`list[${this.fieldValue}]`)
    
    // Don't save if value hasn't changed
    if (this.hasDisplayTarget && this.displayTarget.textContent.trim() === value.trim()) {
      this.cancel()
      return
    }
    
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        list: {
          [this.fieldValue]: value
        }
      })
    })
    .then(response => {
      if (response.ok) {
        return response.json()
      }
      throw new Error("Update failed")
    })
    .then(data => {
      // Update display with new value
      if (this.hasDisplayTarget) {
        this.displayTarget.textContent = data.list_name || data[this.fieldValue]
      }
      // Hide form, show display
      this.hideForm()
      this.showDisplay()
    })
    .catch(error => {
      console.error("Error updating:", error)
      // Revert on error
      this.cancel()
    })
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.save(event)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancel(event)
    }
  }

  // Helper methods for visibility management
  showForm() {
    if (this.hasFormTarget) {
      // Remove d-none, add d-flex to show the form wrapper
      this.formTarget.classList.remove("d-none")
      this.formTarget.classList.add("d-flex")
      // Focus input after a short delay to ensure it's visible
      if (this.hasInputTarget) {
        setTimeout(() => {
          this.inputTarget.focus()
          this.inputTarget.select()
        }, 50)
      }
    }
  }

  hideForm() {
    if (this.hasFormTarget) {
      // Add d-none, remove d-flex
      this.formTarget.classList.add("d-none")
      this.formTarget.classList.remove("d-flex")
    }
  }

  showDisplay() {
    if (this.hasDisplayContainerTarget) {
      this.displayContainerTarget.classList.remove("d-none")
      this.displayContainerTarget.classList.add("d-flex")
    }
  }

  hideDisplay() {
    if (this.hasDisplayContainerTarget) {
      this.displayContainerTarget.classList.add("d-none")
      this.displayContainerTarget.classList.remove("d-flex")
    }
  }
}
