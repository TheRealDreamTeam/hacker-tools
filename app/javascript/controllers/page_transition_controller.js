import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-transition"
// Prevents FOUC (Flash of Unstyled Content) by revealing content when ready
// Removes inline styles from body and adds fouc-ready class once styles and JS are loaded
export default class extends Controller {
  connect() {
    // Prevent FOUC: Reveal content once controller is connected (styles and JS are ready)
    // Remove inline style first (set in body tag), then add fouc-ready class
    this.element.style.visibility = ""
    this.element.style.opacity = ""
    this.element.classList.add("fouc-ready")
    
    // Listen for Turbo navigation events to ensure new pages are visible immediately
    document.addEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.addEventListener("turbo:render", this.handleTurboRender.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.removeEventListener("turbo:render", this.handleTurboRender.bind(this))
  }
  
  handleTurboBeforeRender(event) {
    // Ensure the new body element is visible immediately
    // Remove inline style and add fouc-ready class before swap
    // This prevents any flash of hidden content when the new page is swapped in
    if (event && event.detail && event.detail.newBody) {
      const newBody = event.detail.newBody
      newBody.style.visibility = ""
      newBody.style.opacity = ""
      newBody.classList.add("fouc-ready")
    }
  }
  
  handleTurboRender(event) {
    // Ensure content is visible immediately when Turbo renders the new page
    // Remove inline style and add fouc-ready synchronously
    if (event && event.detail && event.detail.newBody) {
      const newBody = event.detail.newBody
      newBody.style.visibility = ""
      newBody.style.opacity = ""
      newBody.classList.add("fouc-ready")
    } else {
      // Fallback: ensure current body is visible
      this.element.style.visibility = ""
      this.element.style.opacity = ""
      this.element.classList.add("fouc-ready")
    }
  }
}

