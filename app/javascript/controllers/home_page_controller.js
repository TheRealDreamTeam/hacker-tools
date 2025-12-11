import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="home-page"
// Handles category toggling, search debouncing, and upvote functionality on the home page
export default class extends Controller {
  static values = {
    signedIn: Boolean,
    guestMessage: String,
    upvotesText: String
  }

  connect() {
    // Initialize handler storage for this controller instance
    // Each controller instance manages its own handlers independently
    this.buttonHandlers = new WeakMap()
    this.upvoteHandlers = new WeakMap()
    this.searchTimeout = null
    
    // Attach handlers
    this.reattachHandlers()
    
    // Listen for Turbo events to reattach handlers after navigation
    // Use bound methods to maintain proper 'this' context
    this.boundReattachHandlers = this.reattachHandlers.bind(this)
    document.addEventListener("turbo:load", this.boundReattachHandlers)
    document.addEventListener("turbo:frame-load", this.boundReattachHandlers)
  }

  disconnect() {
    // Clean up event listeners
    if (this.boundReattachHandlers) {
      document.removeEventListener("turbo:load", this.boundReattachHandlers)
      document.removeEventListener("turbo:frame-load", this.boundReattachHandlers)
    }
    
    // Clear timeout if it exists
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  reattachHandlers() {
    this.attachCategoryToggle()
    this.attachUpvoteHandlers()
  }

  // Simple client-side toggle to switch between category panels without reload
  attachCategoryToggle() {
    const buttons = Array.from(this.element.querySelectorAll(".category-toggle"))
    const panels = Array.from(this.element.querySelectorAll("[data-category-panel]"))

    if (!buttons.length || !panels.length) return

    const showCategory = (category) => {
      buttons.forEach((btn) => {
        const isActive = btn.dataset.category === category
        btn.classList.toggle("active", isActive)
        btn.setAttribute("aria-pressed", isActive)
      })

      panels.forEach((panel) => {
        const isTarget = panel.dataset.categoryPanel === category
        panel.classList.toggle("d-none", !isTarget)
      })
    }

    buttons.forEach((btn) => {
      // Remove old listener if it exists
      const oldHandler = this.buttonHandlers.get(btn)
      if (oldHandler) {
        btn.removeEventListener("click", oldHandler)
      }
      
      const handler = () => {
        const category = btn.dataset.category
        showCategory(category)
        // Update hidden field in search form
        const categoryInput = this.element.querySelector('input[name="category"]')
        if (categoryInput) {
          categoryInput.value = category
        }
        // Submit form to update results
        const form = btn.closest('.container').querySelector('form')
        if (form) {
          form.requestSubmit()
        }
      }
      
      btn.addEventListener("click", handler)
      this.buttonHandlers.set(btn, handler)
    })
  }

  // Debounce function for search input
  debounceSearch(event) {
    const input = event.target
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      input.form.requestSubmit()
    }, 300) // Wait 300ms after user stops typing
  }

  attachUpvoteHandlers() {
    document.querySelectorAll(".upvote-button").forEach((button) => {
      // Remove old listener if it exists
      const oldHandler = this.upvoteHandlers.get(button)
      if (oldHandler) {
        button.removeEventListener("click", oldHandler)
      }
      
      const countSpan = button.querySelector("[data-upvote-count]")
      const handler = (event) => {
        event.preventDefault()
        event.stopPropagation()

        if (!this.signedInValue) {
          alert(this.guestMessageValue)
          return
        }

        const current = parseInt(button.dataset.count || "0", 10)
        const next = current + 1
        button.dataset.count = next
        if (countSpan) {
          countSpan.textContent = this.upvotesTextValue.replace("%{count}", next)
        }
      }
      
      button.addEventListener("click", handler)
      this.upvoteHandlers.set(button, handler)
    })
  }
}

