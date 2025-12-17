// Stimulus controller for notification interactions
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []
  
  // Mark notification as read when clicked
  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    if (!notificationId) return
    
    // Send PATCH request to mark as read
    fetch(`/notifications/${notificationId}/mark_as_read`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      credentials: "same-origin"
    }).then(response => {
      if (response.ok) {
        // Turbo Stream will handle the update
        return response.text()
      }
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
    }).catch(error => {
      console.error("Error marking notification as read:", error)
    })
  }
}

