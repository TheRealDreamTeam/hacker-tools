import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-transition"
// Handles page transition animations for full page reloads only
// Turbo navigation is fast and doesn't need animations
// Also prevents FOUC (Flash of Unstyled Content) by revealing content when ready
export default class extends Controller {
  connect() {
    // Prevent FOUC: Reveal content once controller is connected (styles and JS are ready)
    // Use requestAnimationFrame to ensure DOM is fully ready
    // Also add a timeout fallback in case requestAnimationFrame is delayed
    requestAnimationFrame(() => {
      this.element.classList.add("fouc-ready")
    })
    
    // Fallback: Ensure content is visible even if requestAnimationFrame is delayed
    // This prevents content from staying hidden if there are any timing issues
    setTimeout(() => {
      this.element.classList.add("fouc-ready")
    }, 100)
    
    // Check if this is a full page reload (not a Turbo visit)
    // Turbo sets a flag in sessionStorage when it handles navigation
    const turboHandled = sessionStorage.getItem("turbo-navigation")
    
    if (!turboHandled) {
      // This is a full page reload - add animation class
      this.element.classList.add("page-transition-enter")
      
      // Remove the class after animation completes to allow re-triggering
      setTimeout(() => {
        this.element.classList.remove("page-transition-enter")
      }, 300) // Match CSS animation duration
    } else {
      // Turbo handled this - clear the flag for next navigation
      sessionStorage.removeItem("turbo-navigation")
    }
    
    // Listen for Turbo navigation events to prevent flickering
    document.addEventListener("turbo:before-visit", this.handleTurboVisit.bind(this))
    document.addEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.addEventListener("turbo:render", this.handleTurboRender.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("turbo:before-visit", this.handleTurboVisit.bind(this))
    document.removeEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.removeEventListener("turbo:render", this.handleTurboRender.bind(this))
  }
  
  handleTurboVisit() {
    // Mark that Turbo is handling this navigation
    // This prevents the animation from triggering on the next page load
    sessionStorage.setItem("turbo-navigation", "true")
  }
  
  handleTurboBeforeRender() {
    // Hide content during Turbo navigation to prevent flickering
    // This ensures smooth transition between pages
    this.element.classList.remove("fouc-ready")
  }
  
  handleTurboRender() {
    // Reveal content after Turbo has rendered the new page
    // Use requestAnimationFrame to ensure rendering is complete
    requestAnimationFrame(() => {
      this.element.classList.add("fouc-ready")
    })
  }
}

