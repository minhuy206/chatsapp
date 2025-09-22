import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton"]

  connect() {
    this.autoResize()
  }

  submit(event) {
    event.preventDefault()

    const content = this.inputTarget.value.trim()
    if (!content) return

    // Disable the submit button
    this.submitButtonTarget.disabled = true

    // Get selected model from sidebar or localStorage
    const selectedModel = this.getSelectedModel()

    // Update hidden field with selected model
    const hiddenInput = document.querySelector('input[name="ai_model"]')
    if (hiddenInput) {
      hiddenInput.value = selectedModel
    }

    // Create the user message bubble immediately
    this.addUserMessage(content)

    // Clear the input
    this.inputTarget.value = ""
    this.autoResize()

    // Submit the form to create conversation and get AI response
    const formData = new FormData(event.target)

    fetch(event.target.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Process any turbo stream responses
      if (html.includes('<turbo-stream')) {
        const tempDiv = document.createElement('div')
        tempDiv.innerHTML = html
        Turbo.renderStreamMessage(tempDiv.innerHTML)
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.addErrorMessage()
    })
    .finally(() => {
      this.submitButtonTarget.disabled = false
    })
  }

  handleKeydown(event) {
    // Submit form on Ctrl/Cmd + Enter
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault()
      this.submit(event)
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = input.scrollHeight + "px"
  }

  addUserMessage(content) {
    const messagesContainer = document.getElementById('chat-messages')

    const messageDiv = document.createElement('div')
    messageDiv.className = 'flex justify-end'
    messageDiv.innerHTML = `
      <div class="max-w-xs lg:max-w-md xl:max-w-2xl">
        <div class="bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-2xl px-4 py-3 shadow-lg">
          <div class="text-sm leading-relaxed">${this.escapeHtml(content)}</div>
          <div class="text-xs opacity-75 mt-2 text-right">
            ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>
      </div>
    `

    messagesContainer.appendChild(messageDiv)
    this.scrollToBottom()
  }

  addErrorMessage() {
    const messagesContainer = document.getElementById('chat-messages')

    const messageDiv = document.createElement('div')
    messageDiv.className = 'flex justify-start'
    messageDiv.innerHTML = `
      <div class="max-w-xs lg:max-w-md xl:max-w-2xl">
        <div class="bg-gray-800 border border-gray-700 rounded-2xl px-4 py-3 shadow-lg">
          <div class="flex items-start space-x-3">
            <div class="flex-shrink-0 mt-1">
              <div class="w-7 h-7 bg-gradient-to-br from-red-500 to-red-600 rounded-lg flex items-center justify-center">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <div class="text-sm leading-relaxed text-gray-100">
                Sorry, I'm having trouble processing your request right now. Please try again.
              </div>
            </div>
          </div>
        </div>
      </div>
    `

    messagesContainer.appendChild(messageDiv)
    this.scrollToBottom()
  }

  scrollToBottom() {
    const messagesContainer = document.getElementById('chat-messages')
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }

  escapeHtml(unsafe) {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")
  }

  getSelectedModel() {
    // First try to get from sidebar selector
    const sidebarSelector = document.querySelector('[data-controller*="sidebar-model-selector"]')
    if (sidebarSelector) {
      const activeButton = sidebarSelector.querySelector('.model-btn.active')
      if (activeButton) {
        return activeButton.dataset.model
      }
    }

    // Fallback to localStorage
    return localStorage.getItem('selectedAIModel') || 'gpt-4o'
  }
}