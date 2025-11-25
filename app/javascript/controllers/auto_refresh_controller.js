import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-refresh"
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 2000 }, // Default 2 seconds
    url: String // Optional URL for frame src
  }

  connect() {
    this.scheduleRefresh()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  scheduleRefresh() {
    this.timeout = setTimeout(() => {
      this.refresh()
      this.scheduleRefresh() // Schedule the next refresh
    }, this.delayValue)
  }

  refresh() {
    // Find the turbo-frame and reload it
    const frame = this.element.closest('turbo-frame') || this.element.querySelector('turbo-frame')
    if (frame) {
      // If a URL is provided and frame doesn't have src, set it
      if (this.hasUrlValue && !frame.src) {
        frame.src = this.urlValue
      }
      frame.reload()
    }
  }
}
