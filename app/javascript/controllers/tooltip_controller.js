import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
// Initializes Bootstrap tooltips for tag links and other elements
export default class extends Controller {
  connect() {
    // Wait for Bootstrap to be available before initializing tooltips
    // Bootstrap is loaded via importmap and should be available globally
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
    // Check if Bootstrap is available before accessing it
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
      const tooltips = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')
      tooltips.forEach(element => {
        const tooltip = bootstrap.Tooltip.getInstance(element)
        if (tooltip) {
          tooltip.dispose()
        }
      })
    }
  }

  initializeTooltips() {
    // Check if Bootstrap is available before initializing tooltips
    if (typeof bootstrap === 'undefined' || !bootstrap.Tooltip) {
      // If Bootstrap isn't available yet, try again after a short delay
      setTimeout(() => this.initializeTooltips(), 100)
      return
    }

    // Find all elements with tooltip data attributes within this controller's element
    const tooltipElements = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')
    
    tooltipElements.forEach(element => {
      // Check if tooltip is already initialized to avoid duplicates
      if (!bootstrap.Tooltip.getInstance(element)) {
        // Get placement from data attribute (data-bs-placement becomes bsPlacement in dataset)
        const placement = element.dataset.bsPlacement || element.getAttribute('data-bs-placement') || 'top'
        
        // Initialize Bootstrap tooltip
        // Bootstrap will automatically read data-bs-title or title attribute for the tooltip content
        new bootstrap.Tooltip(element, {
          trigger: 'hover',
          placement: placement,
          html: false
        })
      }
    })
  }
}


