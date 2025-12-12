import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
// Initializes Bootstrap tooltips for tag links and other elements
export default class extends Controller {
  connect() {
    // Initialize all tooltips within this element
    // Bootstrap tooltips need to be initialized after DOM is ready
    this.initializeTooltips()
    
    // Reinitialize tooltips after Turbo navigation
    // This ensures tooltips work on dynamically loaded content
    this.boundInitializeTooltips = this.initializeTooltips.bind(this)
    document.addEventListener("turbo:load", this.boundInitializeTooltips)
    document.addEventListener("turbo:frame-load", this.boundInitializeTooltips)
  }

  disconnect() {
    // Clean up event listeners
    if (this.boundInitializeTooltips) {
      document.removeEventListener("turbo:load", this.boundInitializeTooltips)
      document.removeEventListener("turbo:frame-load", this.boundInitializeTooltips)
    }
    
    // Dispose of all tooltips in this element
    const tooltips = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')
    tooltips.forEach(element => {
      const tooltip = bootstrap.Tooltip.getInstance(element)
      if (tooltip) {
        tooltip.dispose()
      }
    })
  }

  initializeTooltips() {
    // Find all elements with tooltip data attributes within this controller's element
    const tooltipElements = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')
    
    tooltipElements.forEach(element => {
      // Check if tooltip is already initialized to avoid duplicates
      if (!bootstrap.Tooltip.getInstance(element)) {
        // Initialize Bootstrap tooltip
        new bootstrap.Tooltip(element, {
          trigger: 'hover',
          placement: element.dataset.bsPlacement || 'top',
          html: false
        })
      }
    })
  }
}


