import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-refresh"
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 2000 } // Default 2 seconds
  }

  connect() {
    this.timeout = setTimeout(() => {
      this.refresh()
    }, this.delayValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  refresh() {
    // Find the turbo-frame and reload it
    const frame = this.element.closest('turbo-frame') || this.element.querySelector('turbo-frame')
    if (frame) {
      frame.reload()
    }
  }
}
