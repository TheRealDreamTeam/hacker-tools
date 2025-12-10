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
    
    // Check if fadein class is already present (from before-render hook)
    // If so, preserve it - don't remove it here as it will be removed in handleTurboRender
    const hasFadein = this.element.classList.contains("page-transition-fadein")
    
    // Prevent FOUC: Reveal content once controller is connected (styles and JS are ready)
    // Remove inline style first (set in body tag), then add fouc-ready class
    this.element.style.visibility = ""
    this.element.style.opacity = ""
    this.element.classList.add("fouc-ready", "page-transition-ready")
    
    // If fadein class was present, ensure it stays (it will be removed in handleTurboRender)
    // This prevents the controller from interfering with the fade-in animation
    if (hasFadein) {
      this.element.classList.add("page-transition-fadein")
    }
    
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
    
    // Different page: no fadeout - just prepare for fadein
    // Content will fade in immediately when new page loads
  }
  
  handleTurboBeforeRender(event) {
    // If navigating to a different page, prepare new body for fadein
    if (!this.isSamePage && event && event.detail && event.detail.newBody) {
      const newBody = event.detail.newBody
      
      // CRITICAL: Add fadein class FIRST before making body visible
      // This ensures CSS hides content immediately, preventing flicker
      newBody.classList.add("fouc-ready", "page-transition-ready", "page-transition-fadein")
      
      // Now make body visible (navbar will show, but content stays hidden due to fadein class)
      newBody.style.visibility = ""
      newBody.style.opacity = ""
      
      // Remove any inline styles from content wrapper - let CSS handle it
      // CSS with !important will ensure content stays hidden until fadein class is removed
      const contentWrapper = newBody.querySelector(".page-transition-content")
      if (contentWrapper) {
        // Ensure content wrapper starts hidden (CSS will keep it hidden with fadein class)
        contentWrapper.style.visibility = ""
        contentWrapper.style.opacity = ""
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
      
    }
  }
  
  handleTurboRender(event) {
    // Update current URL after navigation
    this.currentUrl = window.location.href
    
    if (!this.isSamePage) {
      // Different page: ensure fadein class is already applied (from before-render)
      // Body should already be visible with fadein class keeping content hidden
      // Double-check that fadein class is present to prevent flicker
      if (!this.element.classList.contains("page-transition-fadein")) {
        this.element.classList.add("page-transition-fadein")
      }
      
      // Ensure body is visible (navbar should already be showing)
      this.element.style.visibility = ""
      this.element.style.opacity = ""
      this.element.classList.add("fouc-ready", "page-transition-ready")
      
      // Ensure content wrapper exists and is properly set up
      const contentWrapper = this.element.querySelector(".page-transition-content")
      if (contentWrapper) {
        // Remove any inline styles that might interfere - let CSS handle it
        contentWrapper.style.visibility = ""
        contentWrapper.style.opacity = ""
      }
      
      // Trigger fadein by removing fadein class after ensuring DOM and CSS are ready
      // Use requestAnimationFrame to ensure browser has painted the hidden state first
      // This prevents the flicker by ensuring content is hidden before we start the fadein
      // Multiple requestAnimationFrame calls ensure CSS is applied and browser has painted
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          // Double-check that content wrapper is still hidden before starting fadein
          const contentWrapper = this.element.querySelector(".page-transition-content")
          if (contentWrapper) {
            // Force hidden state one more time to prevent any flicker
            contentWrapper.style.opacity = "0"
            contentWrapper.style.visibility = "hidden"
          }
          
          // Small delay to ensure browser has processed the hidden state
          requestAnimationFrame(() => {
            // Now remove fadein class to trigger the fadein animation
            // CSS will handle the transition smoothly
            this.element.classList.remove("page-transition-fadein")
            
            // Clear inline styles so CSS transition can work
            if (contentWrapper) {
              contentWrapper.style.opacity = ""
              contentWrapper.style.visibility = ""
            }
          })
        })
      })
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
      
    }
  }
}


