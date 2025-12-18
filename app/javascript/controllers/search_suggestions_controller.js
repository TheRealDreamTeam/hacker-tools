import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-suggestions"
// Sends debounced requests for search suggestions (min 3 characters)
// and renders simple HTML into a local panel target
export default class extends Controller {
  static values = {
    url: String
  }

  static targets = ["input", "panel"]

  connect() {
    this.timeout = null
    this.lastRequestedQuery = ""
    
    // Bind event handlers so we can remove them later
    this.boundClickOutside = this.handleClickOutside.bind(this)
    this.boundKeyDown = this.handleKeyDown.bind(this)
    
    // Listen for clicks outside the input and panel to dismiss suggestions
    document.addEventListener("click", this.boundClickOutside, true)
    
    // Listen for ESC key to dismiss suggestions
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("keydown", this.boundKeyDown)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Remove event listeners
    document.removeEventListener("click", this.boundClickOutside, true)
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("keydown", this.boundKeyDown)
    }
  }

  onInput(event) {
    const value = event.target.value || ""

    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.timeout = setTimeout(() => {
      this.fetchSuggestions(value)
    }, 250)
  }

  fetchSuggestions(query) {
    if (!this.hasPanelTarget) return

    // Hide suggestions when query is too short
    if (query.length < 3) {
      this.panelTarget.innerHTML = ""
      this.lastRequestedQuery = ""
      return
    }

    this.lastRequestedQuery = query

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("query", query)

    // Include currently selected categories if present (search page)
    const form = this.element.closest("form") || this.element
    if (form) {
      const categoryInputs = form.querySelectorAll('input[name="categories[]"]:checked')
      categoryInputs.forEach((input) => {
        url.searchParams.append("categories[]", input.value)
      })
    }

    // Check if this is the navbar panel or homepage panel (both should have sticky footer)
    const isNavbar = this.panelTarget.id === "navbar-search-suggestions" || 
                     this.panelTarget.id === "mobile-search-suggestions" ||
                     this.panelTarget.hasAttribute("data-is-navbar")
    const isHomepage = this.panelTarget.id === "home-search-suggestions"
    
    // Add navbar flag to URL if it's the navbar or homepage (both get sticky footer)
    if (isNavbar || isHomepage) {
      url.searchParams.set("navbar", "true")
    }
    
    // Add homepage flag to URL if it's the homepage (for positioning above input)
    if (isHomepage) {
      url.searchParams.set("homepage", "true")
    }

    fetch(url.toString(), {
      headers: {
        Accept: "text/html"
      },
      credentials: "same-origin"
    })
      .then((response) => response.text())
      .then((html) => {
        // Ignore out-of-date responses (race condition when user keeps typing / deleting)
        const input = this.hasInputTarget ? this.inputTarget : null
        const current = input ? (input.value || "") : this.lastRequestedQuery
        if (current !== query) return

        this.panelTarget.innerHTML = html
      })
      .catch(() => {
        // Fail silently for suggestions; core search flow is unaffected
      })
  }

  // Hide on blur from the input
  // Use a longer delay to ensure click events on suggestions can fire before panel is cleared
  hide() {
    if (!this.hasPanelTarget) return

    // Defer clearing with longer delay so click events on suggestions can fire
    // This allows users to click on suggestion links before the panel disappears
    setTimeout(() => {
      // Only hide if the panel still exists and user hasn't focused back on input
      if (this.hasPanelTarget && (!this.hasInputTarget || document.activeElement !== this.inputTarget)) {
        this.dismiss()
      }
    }, 200) // Increased from 0ms to 200ms to allow click events to complete
  }

  // Handle clicks outside the input and panel to dismiss suggestions
  handleClickOutside(event) {
    if (!this.hasPanelTarget || !this.panelTarget.innerHTML) return

    // Check if click is outside both the input and the panel
    const clickedInput = this.hasInputTarget && (this.inputTarget === event.target || this.inputTarget.contains(event.target))
    const clickedPanel = this.panelTarget === event.target || this.panelTarget.contains(event.target)
    
    // If click is outside both, dismiss the suggestions
    if (!clickedInput && !clickedPanel) {
      this.dismiss()
    }
  }

  // Handle ESC key to dismiss suggestions
  handleKeyDown(event) {
    if (event.key === "Escape" || event.keyCode === 27) {
      this.dismiss()
      // Optionally blur the input to remove focus
      if (this.hasInputTarget) {
        this.inputTarget.blur()
      }
    }
  }

  // Dismiss suggestions panel
  dismiss() {
    if (!this.hasPanelTarget) return
    this.panelTarget.innerHTML = ""
    this.lastRequestedQuery = ""
  }
}

