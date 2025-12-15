import { Controller } from "@hotwired/stimulus"

// Makes the entire tool card behave like a link to the tool page while
// preserving the default behavior for interactive elements such as buttons,
// links (including tag links), and any element that explicitly opts out via
// data-no-card-nav.
export default class extends Controller {
  static values = {
    url: String
  }

  navigate(event) {
    // If the click originated inside an interactive element, let that element
    // handle it instead of triggering a card-level navigation.
    if (event.target.closest("a, button, [data-no-card-nav]")) {
      return
    }

    if (!this.hasUrlValue) return

    event.preventDefault()

    // Prefer Turbo navigation when available to keep history and transitions
    // consistent with the rest of the Rails app.
    if (window.Turbo && typeof window.Turbo.visit === "function") {
      window.Turbo.visit(this.urlValue)
    } else {
      window.location.href = this.urlValue
    }
  }
}


