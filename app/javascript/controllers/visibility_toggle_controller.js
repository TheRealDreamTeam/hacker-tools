import { Controller } from "@hotwired/stimulus"

console.log("Visibility toggle controller: Module loaded")

// Manual initialization function that works independently of Stimulus
function initializeVisibilityToggle() {
  console.log("Visibility toggle: Manual initialization started")
  const containers = document.querySelectorAll('[data-controller="visibility-toggle"], #list-visibility-form')
  console.log("Visibility toggle: Found containers", containers.length)
  
  containers.forEach((container, index) => {
    console.log(`Visibility toggle: Initializing container ${index}`, container)
    const form = container.querySelector('form')
    const hiddenField = container.querySelector('[data-visibility-toggle-target="hiddenField"]')
    const publicButton = container.querySelector('[data-visibility-toggle-target="publicButton"]')
    const privateButton = container.querySelector('[data-visibility-toggle-target="privateButton"]')
    
    console.log("Visibility toggle: Form found?", !!form)
    console.log("Visibility toggle: Hidden field found?", !!hiddenField)
    console.log("Visibility toggle: Public button found?", !!publicButton)
    console.log("Visibility toggle: Private button found?", !!privateButton)
    
    if (!form || !hiddenField || !publicButton || !privateButton) {
      console.error("Visibility toggle: Missing required elements", { form, hiddenField, publicButton, privateButton })
      return
    }
    
    // Add click handlers directly
    publicButton.addEventListener('click', (e) => {
      console.log("Visibility toggle: Public button clicked (direct listener)")
      e.preventDefault()
      e.stopPropagation()
      
      if (publicButton.classList.contains('active')) {
        console.log("Visibility toggle: Already public, skipping")
        return
      }
      
      hiddenField.value = 'public'
      publicButton.classList.add('active')
      privateButton.classList.remove('active')
      
      console.log("Visibility toggle: Submitting form")
      if (form.requestSubmit) {
        form.requestSubmit()
      } else {
        form.submit()
      }
    })
    
    privateButton.addEventListener('click', (e) => {
      console.log("Visibility toggle: Private button clicked (direct listener)")
      e.preventDefault()
      e.stopPropagation()
      
      if (privateButton.classList.contains('active')) {
        console.log("Visibility toggle: Already private, skipping")
        return
      }
      
      hiddenField.value = 'private'
      privateButton.classList.add('active')
      publicButton.classList.remove('active')
      
      console.log("Visibility toggle: Submitting form")
      if (form.requestSubmit) {
        form.requestSubmit()
      } else {
        form.submit()
      }
    })
    
    console.log("Visibility toggle: Event listeners attached to container", index)
  })
}

// Initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeVisibilityToggle)
} else {
  initializeVisibilityToggle()
}

// Also initialize on Turbo navigation
document.addEventListener('turbo:load', initializeVisibilityToggle)
document.addEventListener('turbo:frame-load', initializeVisibilityToggle)

// Connects to data-controller="visibility-toggle"
// Manages a two-button toggle group for list visibility (Public/Private)
export default class extends Controller {
  static targets = ["hiddenField", "publicButton", "privateButton"]

  connect() {
    console.log("=== Visibility toggle: Controller connected ===", this.element)
    console.log("Visibility toggle: Controller element HTML", this.element.innerHTML.substring(0, 500))
    
    // Find buttons directly and add event listeners as fallback
    const buttons = this.element.querySelectorAll("button[type='button']")
    console.log("Visibility toggle: Found buttons", buttons.length, buttons)
    
    buttons.forEach((button, index) => {
      console.log(`Visibility toggle: Button ${index}:`, button.textContent.trim(), button)
      // Add direct click listener to each button
      button.addEventListener("click", (e) => {
        console.log(`Visibility toggle: Direct click on button ${index}`, button.textContent.trim(), e)
        e.preventDefault()
        e.stopPropagation()
        
        // Determine which button was clicked
        if (button.textContent.trim().toLowerCase().includes("public")) {
          console.log("Visibility toggle: Public button clicked via direct listener")
          this.selectPublic(e)
        } else if (button.textContent.trim().toLowerCase().includes("private")) {
          console.log("Visibility toggle: Private button clicked via direct listener")
          this.selectPrivate(e)
        }
      })
    })
    
    // Add a global click listener on the entire element to catch ANY clicks
    this.element.addEventListener("click", (e) => {
      console.log("Visibility toggle: ANY click detected on element", e.target, "tagName:", e.target.tagName, "classes:", e.target.className)
      console.log("Visibility toggle: Click target has data-action?", e.target.hasAttribute("data-action"))
      if (e.target.hasAttribute("data-action")) {
        console.log("Visibility toggle: data-action value:", e.target.getAttribute("data-action"))
      }
    }, true) // Use capture phase to catch all clicks
    
    // Verify targets are available
    if (!this.hasHiddenFieldTarget) {
      console.error("Visibility toggle: Hidden field target not found")
    } else {
      console.log("Visibility toggle: Hidden field found", this.hiddenFieldTarget, "value:", this.hiddenFieldTarget.value)
    }
    if (!this.hasPublicButtonTarget) {
      console.error("Visibility toggle: Public button target not found")
    } else {
      console.log("Visibility toggle: Public button found", this.publicButtonTarget)
      // Add direct click listener for debugging
      this.publicButtonTarget.addEventListener("click", (e) => {
        console.log("Visibility toggle: Direct click listener on public button", e)
      })
    }
    if (!this.hasPrivateButtonTarget) {
      console.error("Visibility toggle: Private button target not found")
    } else {
      console.log("Visibility toggle: Private button found", this.privateButtonTarget)
      // Add direct click listener for debugging
      this.privateButtonTarget.addEventListener("click", (e) => {
        console.log("Visibility toggle: Direct click listener on private button", e)
      })
    }
    
    // Check if form exists
    const form = this.element.querySelector("form")
    if (form) {
      console.log("Visibility toggle: Form found", form, "action:", form.action, "method:", form.method)
    } else {
      console.error("Visibility toggle: Form not found in element", this.element)
    }
  }

  // Select Public visibility
  selectPublic(event) {
    console.log("Visibility toggle: selectPublic called", event)
    // Prevent any default button behavior
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Don't do anything if already public
    if (this.hasPublicButtonTarget && this.publicButtonTarget.classList.contains("active")) {
      return
    }
    
    // Update hidden field value
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = "public"
    } else {
      console.error("Visibility toggle: Hidden field target not found")
      return
    }
    
    // Update button states - make public active, private inactive
    if (this.hasPublicButtonTarget) {
      this.publicButtonTarget.classList.add("active")
    }
    if (this.hasPrivateButtonTarget) {
      this.privateButtonTarget.classList.remove("active")
    }
    
    // Submit the form (form is inside this.element)
    const form = this.element.querySelector("form")
    if (form) {
      console.log("Visibility toggle: Submitting form", form)
      // Use Turbo's form submission - requestSubmit() should work with Turbo
      if (form.requestSubmit) {
        form.requestSubmit()
      } else {
        // Fallback: create submit button and click it
        const submitButton = document.createElement("button")
        submitButton.type = "submit"
        submitButton.style.display = "none"
        form.appendChild(submitButton)
        submitButton.click()
        form.removeChild(submitButton)
      }
    } else {
      console.error("Visibility toggle: Form not found in element", this.element)
    }
  }

  // Select Private visibility
  selectPrivate(event) {
    console.log("Visibility toggle: selectPrivate called", event)
    // Prevent any default button behavior
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Don't do anything if already private
    if (this.hasPrivateButtonTarget && this.privateButtonTarget.classList.contains("active")) {
      return
    }
    
    // Update hidden field value
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = "private"
    } else {
      console.error("Visibility toggle: Hidden field target not found")
      return
    }
    
    // Update button states - make private active, public inactive
    if (this.hasPrivateButtonTarget) {
      this.privateButtonTarget.classList.add("active")
    }
    if (this.hasPublicButtonTarget) {
      this.publicButtonTarget.classList.remove("active")
    }
    
    // Submit the form (form is inside this.element)
    const form = this.element.querySelector("form")
    if (form) {
      console.log("Visibility toggle: Submitting form", form)
      // Use Turbo's form submission - requestSubmit() should work with Turbo
      if (form.requestSubmit) {
        form.requestSubmit()
      } else {
        // Fallback: create submit button and click it
        const submitButton = document.createElement("button")
        submitButton.type = "submit"
        submitButton.style.display = "none"
        form.appendChild(submitButton)
        submitButton.click()
        form.removeChild(submitButton)
      }
    } else {
      console.error("Visibility toggle: Form not found in element", this.element)
    }
  }

  // Update button states after Turbo Stream response
  updateButtons() {
    // Get the current visibility value from the hidden field
    const visibility = this.hiddenFieldTarget.value
    
    // Update button states based on current visibility
    if (visibility === "public") {
      if (this.hasPublicButtonTarget) {
        this.publicButtonTarget.classList.add("active")
      }
      if (this.hasPrivateButtonTarget) {
        this.privateButtonTarget.classList.remove("active")
      }
    } else {
      if (this.hasPrivateButtonTarget) {
        this.privateButtonTarget.classList.add("active")
      }
      if (this.hasPublicButtonTarget) {
        this.publicButtonTarget.classList.remove("active")
      }
    }
  }
}
