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
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
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
  hide() {
    if (!this.hasPanelTarget) return

    // Defer clearing so click events on suggestions can still fire
    setTimeout(() => {
      this.panelTarget.innerHTML = ""
      this.lastRequestedQuery = ""
    }, 0)
  }
}

