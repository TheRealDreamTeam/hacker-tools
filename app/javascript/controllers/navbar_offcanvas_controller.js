import { Controller } from "@hotwired/stimulus"

// Manages the offcanvas sidebar menu behavior:
// - Opens by default on large screens (≥lg breakpoint)
// - Can be toggled closed/open on all screen sizes
// - Handles responsive behavior when screen size changes
export default class extends Controller {
  static targets = ["offcanvas", "toggler", "newSubmissionBtn"]

  connect() {
    this.offcanvas = null
    this.isLargeScreen = this.checkLargeScreen()
    
    // Initialize Bootstrap offcanvas instance
    if (this.hasOffcanvasTarget) {
      // Wait for Bootstrap to be available
      if (typeof bootstrap !== 'undefined' && bootstrap.Offcanvas) {
        this.initializeOffcanvas()
      } else {
        // If Bootstrap isn't available yet, try again after a short delay
        setTimeout(() => this.initializeOffcanvas(), 100)
      }
    }
  }

  initializeOffcanvas() {
    if (!this.hasOffcanvasTarget || typeof bootstrap === 'undefined' || !bootstrap.Offcanvas) {
      return
    }

    this.offcanvas = new bootstrap.Offcanvas(this.offcanvasTarget)
    
    // Open by default on large screens
    if (this.isLargeScreen) {
      this.offcanvas.show()
    }
    
    // Listen for screen size changes
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)
    
    // Listen for offcanvas events to update state
    this.offcanvasTarget.addEventListener("shown.bs.offcanvas", this.handleShown.bind(this))
    this.offcanvasTarget.addEventListener("hidden.bs.offcanvas", this.handleHidden.bind(this))
  }

  disconnect() {
    if (this.handleResize) {
      window.removeEventListener("resize", this.handleResize)
    }
    
    if (this.offcanvas) {
      this.offcanvas.dispose()
    }
  }

  // Check if current screen size is large (≥lg breakpoint, 992px)
  checkLargeScreen() {
    return window.innerWidth >= 992
  }

  // Handle window resize to open/close offcanvas based on screen size
  handleResize() {
    const wasLargeScreen = this.isLargeScreen
    this.isLargeScreen = this.checkLargeScreen()
    
    if (this.offcanvas) {
      const isShown = this.offcanvasTarget.classList.contains("show")
      
      // If transitioning to large screen and offcanvas is closed, open it
      if (!wasLargeScreen && this.isLargeScreen && !isShown) {
        this.offcanvas.show()
      }
      // If transitioning from large to small screen and offcanvas is open, close it
      // (optional - you might want to keep it open, but closing is cleaner UX)
      else if (wasLargeScreen && !this.isLargeScreen && isShown) {
        this.offcanvas.hide()
      }
    }
  }

  // Handle offcanvas shown event
  handleShown() {
    // Update any UI state if needed
  }

  // Handle offcanvas hidden event
  handleHidden() {
    // Update any UI state if needed
  }
}

