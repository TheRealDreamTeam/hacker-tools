import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-transition"
// Handles smooth page transitions with fadeout/fadein animations
// Prevents FOUC (Flash of Unstyled Content) by revealing content when ready
// Skips animation when navigating to the same page
export default class extends Controller {
  connect() {
    // Track current URL to detect same-page navigation
    this.currentUrl = window.location.href
    
    // Create transition overlay that persists across Turbo swaps
    // This overlay will handle the fadeout/fadein effect
    this.createTransitionOverlay()
    
    // Prevent FOUC: Reveal content once controller is connected (styles and JS are ready)
    // Remove inline style first (set in body tag), then add fouc-ready class
    this.element.style.visibility = ""
    this.element.style.opacity = ""
    this.element.classList.add("fouc-ready", "page-transition-ready")
    
    // Listen for Turbo navigation events to handle page transitions
    document.addEventListener("turbo:before-visit", this.handleTurboBeforeVisit.bind(this))
    document.addEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.addEventListener("turbo:render", this.handleTurboRender.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("turbo:before-visit", this.handleTurboBeforeVisit.bind(this))
    document.removeEventListener("turbo:before-render", this.handleTurboBeforeRender.bind(this))
    document.removeEventListener("turbo:render", this.handleTurboRender.bind(this))
    
    // Clean up overlay if it exists
    if (this.overlay) {
      this.overlay.remove()
    }
  }
  
  createTransitionOverlay() {
    // Create a fixed overlay that covers the entire viewport
    // This overlay persists across Turbo body swaps and creates fade effect
    this.overlay = document.createElement("div")
    this.overlay.id = "page-transition-overlay"
    this.overlay.className = "page-transition-overlay"
    document.documentElement.appendChild(this.overlay)
  }
  
  handleTurboBeforeVisit(event) {
    // Update current URL from actual window location (more reliable than stored value)
    // This ensures accurate comparison, especially on first navigation
    const currentUrl = window.location.href
    const targetUrl = event.detail.url
    
    // Normalize URLs for comparison - remove trailing slashes and hash fragments
    const normalizeUrl = (url) => {
      return url.split('#')[0].replace(/\/$/, '')
    }
    
    const currentUrlNormalized = normalizeUrl(currentUrl)
    const targetUrlNormalized = normalizeUrl(targetUrl)
    
    this.isSamePage = currentUrlNormalized === targetUrlNormalized
    
    // If navigating to the same page, prevent Turbo from navigating at all
    if (this.isSamePage) {
      // Prevent navigation - just reload the page without Turbo
      event.preventDefault()
      // Optionally, you could do a full page reload here if needed
      // window.location.reload()
      return
    }
    
    // Different page: start fadeout animation
    // Start fadeout by fading the body and showing overlay
    this.element.classList.add("page-transition-fadeout")
    
    // Show overlay to create smooth transition effect
    this.overlay.style.display = "block"
    this.overlay.style.opacity = "0"
    
    // Fade overlay in (creating fadeout effect)
    requestAnimationFrame(() => {
      this.overlay.style.opacity = "1"
    })
  }
  
  handleTurboBeforeRender(event) {
    // If navigating to a different page, prepare new body for fadein
    if (!this.isSamePage && event && event.detail && event.detail.newBody) {
      const newBody = event.detail.newBody
      
      // Ensure new body is visible (for navbar), but content is hidden initially
      newBody.style.visibility = ""
      newBody.style.opacity = ""
      newBody.classList.add("fouc-ready", "page-transition-ready", "page-transition-fadein")
      
      // Hide the main content wrapper (navbar stays visible)
      const contentWrapper = newBody.querySelector(".page-transition-content")
      if (contentWrapper) {
        contentWrapper.style.visibility = "hidden"
        contentWrapper.style.opacity = "0"
      }
    } else if (this.isSamePage && event && event.detail && event.detail.newBody) {
      // Same page: ensure new body is visible immediately (no animation)
      const newBody = event.detail.newBody
      newBody.style.visibility = ""
      newBody.style.opacity = ""
      newBody.classList.add("fouc-ready", "page-transition-ready")
      
      // Ensure content wrapper is visible
      const contentWrapper = newBody.querySelector(".page-transition-content")
      if (contentWrapper) {
        contentWrapper.style.visibility = ""
        contentWrapper.style.opacity = ""
      }
      
      // Hide overlay if it was shown
      if (this.overlay) {
        this.overlay.style.display = "none"
      }
    }
  }
  
  handleTurboRender(event) {
    // Update current URL after navigation
    this.currentUrl = window.location.href
    
    // Remove fadeout class from new body (in case it was inherited)
    this.element.classList.remove("page-transition-fadeout")
    
    if (!this.isSamePage) {
      // Different page: wait for fadeout to complete, then fade in new page
      // Fadeout takes 125ms, so wait that long before starting fadein
      setTimeout(() => {
        // Hide overlay (fadeout complete)
        if (this.overlay) {
          this.overlay.style.display = "none"
        }
        
        // Show body (navbar is already visible)
        this.element.style.visibility = ""
        this.element.style.opacity = ""
        this.element.classList.add("fouc-ready", "page-transition-ready")
        
        // Show and fade in content wrapper (navbar stays visible throughout)
        const contentWrapper = this.element.querySelector(".page-transition-content")
        if (contentWrapper) {
          contentWrapper.style.visibility = ""
          contentWrapper.style.opacity = ""
        }
        
        // Trigger fadein by removing fadein class after ensuring DOM is ready
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            this.element.classList.remove("page-transition-fadein")
          })
        })
      }, 125) // Wait for fadeout to complete (125ms)
    } else {
      // Same page: ensure content is visible immediately (no animation)
      this.element.style.visibility = ""
      this.element.style.opacity = ""
      this.element.classList.add("fouc-ready", "page-transition-ready")
      this.element.classList.remove("page-transition-fadein")
      
      // Ensure content wrapper is visible
      const contentWrapper = this.element.querySelector(".page-transition-content")
      if (contentWrapper) {
        contentWrapper.style.visibility = ""
        contentWrapper.style.opacity = ""
      }
      
      // Hide overlay if it was shown
      if (this.overlay) {
        this.overlay.style.display = "none"
      }
    }
  }
}

