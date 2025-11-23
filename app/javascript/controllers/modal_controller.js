import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "fileName"]

  connect() {
    // Handle ESC key to close modal
    this.boundHandleKeyup = this.handleKeyup.bind(this)
    document.addEventListener("keyup", this.boundHandleKeyup)
  }

  disconnect() {
    document.removeEventListener("keyup", this.boundHandleKeyup)
  }

  close(event) {
    // Only close if clicking on the backdrop (not the panel)
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) {
      return
    }

    // Navigate to documents index, which will clear the turbo frame
    window.Turbo.visit(this.element.closest("turbo-frame").dataset.src || "/documents")
  }

  handleKeyup(event) {
    if (event.key === "Escape") {
      window.Turbo.visit("/documents")
    }
  }

  updateFileName(event) {
    const file = event.target.files[0]

    if (file && this.hasFileNameTarget) {
      // Display file name with a checkmark icon
      this.fileNameTarget.innerHTML = `
        <svg class="inline-block h-5 w-5 text-green-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <span class="font-semibold">${file.name}</span>
        <span class="text-gray-500 ml-2">(${this.formatFileSize(file.size)})</span>
      `
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 10) / 10 + ' ' + sizes[i]
  }
}
