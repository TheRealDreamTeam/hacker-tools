import { Controller } from "@hotwired/stimulus"

// Minimal FOUC guard: show body as soon as Stimulus is ready
// and ensure Turbo swaps keep the new body visible immediately.
export default class extends Controller {
  connect() {
    this.reveal(this.element)
    document.addEventListener("turbo:before-render", this.handleBeforeRender)
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.handleBeforeRender)
  }

  handleBeforeRender = (event) => {
    const newBody = event?.detail?.newBody
    if (!newBody) return

    this.reveal(newBody)

    const contentWrapper = newBody.querySelector(".page-transition-content")
    if (contentWrapper) this.reveal(contentWrapper)
  }

  reveal(element) {
    element.style.visibility = ""
    element.style.opacity = ""
    element.classList.add("fouc-ready")
    element.classList.remove("page-transition-fadein", "page-transition-ready")
  }
}


