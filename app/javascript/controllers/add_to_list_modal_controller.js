import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-to-list-modal"
// This controller manages the global "add to list" modal
// It reads data from the button that triggers it and populates the modal dynamically
// The controller is attached to the modal element itself so it can manage form submissions
export default class extends Controller {
  static targets = ["modal", "title", "toolId", "form", "body", "listGroup"]

  connect() {
    // Initialize Bootstrap modal instance
    this.modalInstance = new bootstrap.Modal(this.modalTarget)
    // Store bound handlers so we can remove them later
    this.boundHandlers = {}
    
    // Set up form submission listeners when controller connects
    this.setupFormListeners()
    
    // Listen for custom events from buttons that want to open the modal
    // This allows buttons outside the modal to trigger it
    this.boundHandlers.openModal = this.handleOpenModalEvent.bind(this)
    document.addEventListener("add-to-list-modal:open", this.boundHandlers.openModal)
  }

  disconnect() {
    // Remove event listeners if they exist
    this.removeFormListeners()
    
    // Remove custom event listener
    if (this.boundHandlers.openModal) {
      document.removeEventListener("add-to-list-modal:open", this.boundHandlers.openModal)
    }
    
    // Dispose Bootstrap modal instance when controller disconnects
    if (this.modalInstance) {
      this.modalInstance.dispose()
      this.modalInstance = null
    }
  }

  // Set up form submission listeners
  setupFormListeners() {
    if (!this.hasFormTarget) return
    
    // Remove any existing listeners first
    this.removeFormListeners()
    
    // Set up new listeners
    this.boundHandlers.turboSubmitEnd = this.handleTurboSubmitEnd.bind(this)
    this.formTarget.addEventListener("turbo:submit-end", this.boundHandlers.turboSubmitEnd)
  }

  // Remove form event listeners
  removeFormListeners() {
    if (this.hasFormTarget && this.boundHandlers.turboSubmitEnd) {
      this.formTarget.removeEventListener("turbo:submit-end", this.boundHandlers.turboSubmitEnd)
      this.boundHandlers.turboSubmitEnd = null
    }
  }

  // Handle Turbo form submission end - close modal after response is processed
  handleTurboSubmitEnd(event) {
    // Close modal after Turbo has processed the response (redirect or error)
    // This ensures the modal closes regardless of whether it's a redirect or error response
    if (this.modalInstance) {
      // Use setTimeout to ensure the modal closes after Turbo has processed the response
      setTimeout(() => {
        if (this.modalInstance) {
          this.modalInstance.hide()
        }
      }, 100)
    }
  }

  // Handle custom event from button (for buttons outside the modal)
  handleOpenModalEvent(event) {
    const { toolId, toolName, lists } = event.detail
    this.openModal(toolId, toolName, lists)
  }

  // Handle direct action from button (when button has data-action)
  open(event) {
    event.preventDefault()
    
    // Get values from the button that was clicked (the element that triggered the event)
    const button = event.currentTarget
    const toolId = parseInt(button.dataset.addToListModalToolIdValue)
    const toolName = button.dataset.addToListModalToolNameValue
    const lists = JSON.parse(button.dataset.addToListModalListsValue || "[]")
    
    this.openModal(toolId, toolName, lists)
  }

  // Internal method to open the modal with the provided data
  openModal(toolId, toolName, lists) {
    // Validate that required targets exist
    if (!this.hasTitleTarget || !this.hasToolIdTarget || !this.hasListGroupTarget) {
      console.error("Add to list modal: Required targets not found")
      return
    }

    // Update modal title with tool name
    this.titleTarget.textContent = `Add "${toolName}" to lists`

    // Set tool_id in hidden field
    this.toolIdTarget.value = toolId

    // Populate list checkboxes
    this.populateLists(lists)

    // Show modal
    if (this.modalInstance) {
      this.modalInstance.show()
    }
  }

  populateLists(lists) {
    if (!this.hasListGroupTarget) {
      console.error("Add to list modal: List group target not found")
      return
    }

    // Clear existing list items
    this.listGroupTarget.innerHTML = ""

    // Create list items for each list
    lists.forEach(list => {
      const listItem = document.createElement("div")
      listItem.className = "list-group-item"

      const formCheck = document.createElement("div")
      formCheck.className = "form-check"

      const checkbox = document.createElement("input")
      checkbox.type = "checkbox"
      checkbox.name = "list_ids[]"
      checkbox.value = list.id
      checkbox.id = `list_${list.id}`
      checkbox.className = "form-check-input"
      checkbox.checked = list.has_tool

      const label = document.createElement("label")
      label.htmlFor = `list_${list.id}`
      label.className = "form-check-label"
      label.textContent = list.name

      formCheck.appendChild(checkbox)
      formCheck.appendChild(label)

      // Add badge if tool is already in list
      if (list.has_tool) {
        const badge = document.createElement("span")
        badge.className = "badge bg-secondary ms-2"
        badge.textContent = "Already in list"
        label.appendChild(badge)
      }

      listItem.appendChild(formCheck)
      this.listGroupTarget.appendChild(listItem)
    })
  }
}

