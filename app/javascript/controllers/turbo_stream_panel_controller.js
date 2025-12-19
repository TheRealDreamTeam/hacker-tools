import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-stream-panel"
// Ensures Turbo Stream updates work by temporarily showing hidden panels during processing
export default class extends Controller {
  connect() {
    // Debug: Log connection
    console.log('[Turbo Stream Panel] Controller connected')
    
    // Listen for form submissions (earliest point) to show panels before request
    this.boundHandleSubmitStart = this.handleSubmitStart.bind(this)
    
    // Listen for Turbo Stream events to ensure panels are visible during updates
    this.boundHandleBeforeStreamRender = this.handleBeforeStreamRender.bind(this)
    this.boundHandleAfterStreamRender = this.handleAfterStreamRender.bind(this)
    this.boundHandleStreamRender = this.handleStreamRender.bind(this)
    
    // Also listen for clicks on forms directly (earlier than submit-start)
    this.boundHandleClick = this.handleClick.bind(this)
    document.addEventListener("click", this.boundHandleClick, true) // Capture phase
    
    // Intercept form submissions before they're sent
    document.addEventListener("turbo:submit-start", this.boundHandleSubmitStart, true) // Use capture phase
    
    document.addEventListener("turbo:before-stream-render", this.boundHandleBeforeStreamRender)
    document.addEventListener("turbo:stream-render", this.boundHandleStreamRender)
    document.addEventListener("turbo:after-stream-render", this.boundHandleAfterStreamRender)
    
    // Also listen for turbo:load to ensure controller works after page loads
    this.boundHandleTurboLoad = this.handleTurboLoad.bind(this)
    document.addEventListener("turbo:load", this.boundHandleTurboLoad)
    
    // Track which panels we've temporarily shown
    this.temporarilyShownPanels = new Set()
    
    // Run initial check
    this.ensureUpdatesApplied()
  }
  
  handleTurboLoad() {
    console.log('[Turbo Stream Panel] Turbo load event - controller should be active')
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClick, true)
    document.removeEventListener("turbo:submit-start", this.boundHandleSubmitStart, true)
    document.removeEventListener("turbo:before-stream-render", this.boundHandleBeforeStreamRender)
    document.removeEventListener("turbo:stream-render", this.boundHandleStreamRender)
    document.removeEventListener("turbo:after-stream-render", this.boundHandleAfterStreamRender)
    if (this.boundHandleTurboLoad) {
      document.removeEventListener("turbo:load", this.boundHandleTurboLoad)
    }
  }

  // Intercept clicks on interaction buttons (earliest possible point)
  handleClick(event) {
    const target = event.target
    // Check if click is on or inside an interaction button form
    const form = target.closest('form[action*="/upvote"], form[action*="/follow"], form[action*="/favorite"]')
    if (form) {
      console.log('[Turbo Stream Panel] Click detected on interaction form:', form.action)
      // Show all panels immediately and synchronously
      this.showAllPanels()
      // Don't prevent default - let the form submit normally
    }
  }

  // When form submission starts, show all panels immediately
  // This happens before the request is sent, ensuring panels are visible
  // when the Turbo Stream response arrives
  handleSubmitStart(event) {
    const form = event.target
    // Check if this is an interaction form (upvote, follow, favorite)
    if (form && form.action && (form.action.includes('/upvote') || form.action.includes('/follow') || form.action.includes('/favorite'))) {
      // Show all panels immediately and synchronously
      this.showAllPanels()
      
      // Debug: Log to verify this is being called
      if (window.console && console.log) {
        console.log('[Turbo Stream Panel] Showing all panels on form submit:', form.action)
      }
    }
  }

  // Before Turbo Stream renders, show all panels to ensure elements are accessible
  handleBeforeStreamRender(event) {
    // Show all hidden panels immediately and synchronously
    // This MUST happen before Turbo Stream tries to find elements
    this.showAllPanels()
    
    // Debug: Log to verify this is being called
    if (window.console && console.log) {
      console.log('[Turbo Stream Panel] Showing all panels before stream render')
    }
  }

  // During Turbo Stream render, ensure panels stay visible
  handleStreamRender(event) {
    // Panels should already be visible from before-stream-render
    // But ensure they're still visible
    this.showAllPanels()
  }

  // After Turbo Stream renders, re-hide panels that aren't the active category
  handleAfterStreamRender(event) {
    // Small delay to ensure all updates are processed
    setTimeout(() => {
      this.hideInactivePanels()
    }, 50)
    
    // Debug: Log to verify this is being called
    console.log('[Turbo Stream Panel] After stream render')
  }
  
  // Fallback: Manually update elements if Turbo Stream couldn't find them
  // This runs after a delay to catch any elements Turbo Stream missed
  ensureUpdatesApplied() {
    setTimeout(() => {
      // Check if any interaction containers need updating
      // This is a fallback in case Turbo Stream couldn't find elements
      const allInteractionContainers = document.querySelectorAll('[id$="_interactions"]')
      console.log('[Turbo Stream Panel] Found interaction containers:', allInteractionContainers.length)
    }, 200)
  }

  // Helper: Show all hidden category panels
  // With position: absolute off-screen, elements are always in DOM
  // But we still show them for visual consistency
  showAllPanels() {
    const allPanels = document.querySelectorAll('[data-category-panel]')
    let shownCount = 0
    allPanels.forEach(panel => {
      if (panel.classList.contains('category-panel-hidden')) {
        // Remove hidden class to make panel visible
        panel.classList.remove('category-panel-hidden')
        this.temporarilyShownPanels.add(panel)
        shownCount++
      }
    })
    if (shownCount > 0) {
      console.log(`[Turbo Stream Panel] Showed ${shownCount} hidden panels`)
    }
  }

  // Helper: Re-hide panels that aren't the active category
  hideInactivePanels() {
    // Get the current active category from URL or default to 'trending'
    const urlParams = new URLSearchParams(window.location.search)
    const activeCategory = urlParams.get('category') || 'trending'
    
    // Re-hide any panels we temporarily showed, unless they're the active category
    this.temporarilyShownPanels.forEach(panel => {
      const panelCategory = panel.dataset.categoryPanel
      if (panelCategory !== activeCategory) {
        panel.classList.add('category-panel-hidden')
      }
    })
    
    // Clear the set for the next update
    this.temporarilyShownPanels.clear()
  }
}

