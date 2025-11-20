import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "loading"]

  connect() {
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  startLoading() {
    this.disableInput()
    this.showLoading()
  }

  stopLoading() {
    this.enableInput()
    this.hideLoading()
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.clearInput()
    }
  }

  disableInput() {
    this.inputTarget.disabled = true
    this.submitTarget.disabled = true
  }

  enableInput() {
    this.inputTarget.disabled = false
    this.submitTarget.disabled = false
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden")
  }

  clearInput() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }
}
