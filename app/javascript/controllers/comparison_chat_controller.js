import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messageInput", "submitButton"]

  connect() {
    this.setupAutoResize()
  }

  handleKeydown(event) {
    if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
      event.preventDefault()
      this.sendMessage(event)
    }
  }

  sendMessage(event) {
    const form = event.target.closest('form')
    const formData = new FormData(form)
    const content = formData.get('content')?.trim()

    if (!content) {
      return false
    }

    // Disable form during submission
    this.disableForm(true)

    return true // Allow form submission
  }

  // Private methods
  setupAutoResize() {
    const textareas = this.element.querySelectorAll('textarea')
    textareas.forEach(textarea => {
      textarea.addEventListener('input', () => {
        textarea.style.height = 'auto'
        textarea.style.height = Math.min(textarea.scrollHeight, 200) + 'px'
      })
    })
  }

  disableForm(disabled) {
    const form = this.element.querySelector('form')
    if (!form) return

    const inputs = form.querySelectorAll('input, textarea, button')
    inputs.forEach(input => {
      input.disabled = disabled
    })

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.textContent = disabled ? 'Comparing...' : 'Compare'
    }

    // Re-enable after a short delay to allow Turbo to handle the response
    if (disabled) {
      setTimeout(() => {
        this.disableForm(false)
        // Clear the textarea
        const textarea = form.querySelector('textarea')
        if (textarea) {
          textarea.value = ''
          textarea.style.height = 'auto'
        }
      }, 1000)
    }
  }

  scrollToBottom() {
    const messagesContainer = document.getElementById('comparison-messages')
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
}