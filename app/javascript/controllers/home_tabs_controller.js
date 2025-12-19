import { Controller } from "@hotwired/stimulus"

// Handles tab switching on the home page using Turbo Streams
// When a tab is clicked, it makes a Turbo request to load the new category
// The server responds with Turbo Streams that update the list and tab states
export default class extends Controller {
  static targets = ["tab"]

  connect() {
    // Turbo handles the navigation automatically via link clicks
    // This controller is mainly for future enhancements if needed
  }
}

