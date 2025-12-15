import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-to-list-modal"
// This controller manages the global "add to list" modal
// It reads data from the button that triggers it and populates the modal dynamically
// The controller is attached to the modal element itself so it can manage form submissions
export default class extends Controller {
  static targets = ["modal", "title", "toolId", "submissionId", "form", "body", "listGroup", "selectMessage", "noListsMessage", "submitButton"]

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
    const { type, toolId, toolName, submissionId, submissionName, lists } = event.detail
    
    if (type === "submission") {
      this.openModalForSubmission(submissionId, submissionName, lists)
    } else if (type === "tool") {
      this.openModalForTool(toolId, toolName, lists)
    } else {
      console.error("Add to list modal: Unknown type", type)
    }
  }

  // Handle direct action from button (when button has data-action)
  open(event) {
    event.preventDefault()
    
    // Get values from the button that was clicked (the element that triggered the event)
    const button = event.currentTarget
    const toolId = button.dataset.addToListModalToolIdValue ? parseInt(button.dataset.addToListModalToolIdValue) : null
    const toolName = button.dataset.addToListModalToolNameValue
    const submissionId = button.dataset.addToListModalSubmissionIdValue ? parseInt(button.dataset.addToListModalSubmissionIdValue) : null
    const submissionName = button.dataset.addToListModalSubmissionNameValue
    const lists = JSON.parse(button.dataset.addToListModalListsValue || "[]")
    
    if (submissionId && submissionName) {
      this.openModalForSubmission(submissionId, submissionName, lists)
    } else if (toolId && toolName) {
      this.openModalForTool(toolId, toolName, lists)
    } else {
      console.error("Add to list modal: Missing required values")
    }
  }

  // Internal method to open the modal for a tool
  openModalForTool(toolId, toolName, lists) {
    // Validate that required targets exist
    if (!this.hasTitleTarget || !this.hasToolIdTarget || !this.hasListGroupTarget) {
      console.error("Add to list modal: Required targets not found")
      return
    }

    // Update form action to use tool route
    if (this.hasFormTarget) {
      this.formTarget.action = this.formTarget.dataset.toolAction || "/lists/add_tool_to_multiple"
    }

    // Hide submission field, show tool field
    if (this.hasSubmissionIdTarget) {
      this.submissionIdTarget.style.display = "none"
      this.submissionIdTarget.value = ""
    }
    if (this.hasToolIdTarget) {
      this.toolIdTarget.style.display = "block"
    }

    // Update modal title with tool name
    this.titleTarget.textContent = `Add "${toolName}" to lists`

    // Set tool_id in hidden field
    this.toolIdTarget.value = toolId

    // Populate list checkboxes
    this.populateLists(lists, "has_tool")

    // Show modal
    if (this.modalInstance) {
      this.modalInstance.show()
    }
  }

  // Internal method to open the modal for a submission
  openModalForSubmission(submissionId, submissionName, lists) {
    // Validate that required targets exist
    if (!this.hasTitleTarget || !this.hasSubmissionIdTarget || !this.hasListGroupTarget) {
      console.error("Add to list modal: Required targets not found")
      return
    }

    // Update form action to use submission route
    if (this.hasFormTarget) {
      this.formTarget.action = this.formTarget.dataset.submissionAction || "/lists/add_submission_to_multiple"
    }

    // Hide tool field, show submission field
    if (this.hasToolIdTarget) {
      this.toolIdTarget.style.display = "none"
      this.toolIdTarget.value = ""
    }
    if (this.hasSubmissionIdTarget) {
      this.submissionIdTarget.style.display = "block"
    }

    // Update modal title with submission name
    this.titleTarget.textContent = `Add "${submissionName}" to lists`

    // Set submission_id in hidden field
    this.submissionIdTarget.value = submissionId

    // Populate list checkboxes
    this.populateLists(lists, "has_submission")

    // Show modal
    if (this.modalInstance) {
      this.modalInstance.show()
    }
  }

  populateLists(lists, hasKey = "has_tool") {
    if (!this.hasListGroupTarget) {
      console.error("Add to list modal: List group target not found")
      return
    }

    // Clear existing list items
    this.listGroupTarget.innerHTML = ""

    // Check if user has any lists
    if (!lists || lists.length === 0) {
      // Show "no lists" message and hide form elements
      if (this.hasSelectMessageTarget) {
        this.selectMessageTarget.classList.add("d-none")
      }
      if (this.hasNoListsMessageTarget) {
        this.noListsMessageTarget.classList.remove("d-none")
      }
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.classList.add("d-none")
      }
      return
    }

    // Hide "no lists" message and show form elements
    if (this.hasSelectMessageTarget) {
      this.selectMessageTarget.classList.remove("d-none")
    }
    if (this.hasNoListsMessageTarget) {
      this.noListsMessageTarget.classList.add("d-none")
    }
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.remove("d-none")
    }

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
      checkbox.checked = list[hasKey] || false

      const label = document.createElement("label")
      label.htmlFor = `list_${list.id}`
      label.className = "form-check-label"
      label.textContent = list.name

      formCheck.appendChild(checkbox)
      formCheck.appendChild(label)

      // Add badge if item is already in list
      if (list[hasKey]) {
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

