import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-filters"
// - Submits the search form on explicit user confirmation (button click)
// - Supports a "select all" toggle for categories without auto-submitting
export default class extends Controller {
  submit() {
    if (this.element.requestSubmit) {
      this.element.requestSubmit()
    }
  }

  toggleAll(event) {
    const checked = event.target.checked
    const inputs = this.element.querySelectorAll('input[name="categories[]"]')

    inputs.forEach((input) => {
      input.checked = checked
    })
  }
}

