import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "submitButton"]

  connect() {
    this.autoResize()
  }

  submit(event) {
    // Disable the submit button to prevent double submission
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Sending..."

    // Show typing indicator
    this.showTypingIndicator()
  }

  handleKeydown(event) {
    // Submit form on Ctrl/Cmd + Enter
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = input.scrollHeight + "px"
  }

  showTypingIndicator() {
    const indicator = document.getElementById("typing-indicator")
    if (indicator) {
      indicator.classList.remove("hidden")
    }
  }

  hideTypingIndicator() {
    const indicator = document.getElementById("typing-indicator")
    if (indicator) {
      indicator.classList.add("hidden")
    }
  }

  // Reset form after successful submission
  reset() {
    this.inputTarget.value = ""
    this.autoResize()
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = "Send"
    this.hideTypingIndicator()
    this.inputTarget.focus()
  }

  // Handle form submission errors
  error() {
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = "Send"
    this.hideTypingIndicator()
  }
}