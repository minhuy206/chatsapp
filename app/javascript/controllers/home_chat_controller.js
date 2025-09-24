import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton", "status", "charCount"]
  static values = { title: String }

  connect() {
    this.autoResize()
    this.setupCharCounter()
    this.currentConversationId = null
    this.selectedModel = "gpt-4o"
  }

  submit(event) {
    event.preventDefault()

    const content = this.inputTarget.value.trim()
    if (!content) return

    // Disable the submit button
    this.submitButtonTarget.disabled = true

    // Get selected model from sidebar or localStorage
    const selectedModel = this.getSelectedModel()

    // Update hidden field with selected model (if not already handled by model selector)
    const hiddenInput = this.element.querySelector('input[name="ai_model"]')
    if (hiddenInput) {
      hiddenInput.value = selectedModel
    }

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
      // Enhanced error handling with environment awareness
      if (Rails.env === 'development') {
        console.error('Chat Error:', error)
      }

      // Track errors for monitoring (when available)
      if (window.errorTracker) {
        window.errorTracker.captureException(error, {
          context: 'chat_submission',
          action: 'form_submit'
        })
      }

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
    // First try to get from model selector
    const modelSelector = document.querySelector('[data-controller*="model-selector"]')
    if (modelSelector) {
      const hiddenField = modelSelector.querySelector('input[name="ai_model"]')
      if (hiddenField && hiddenField.value) {
        return hiddenField.value
      }
    }

    // Fallback to localStorage
    const saved = localStorage.getItem('selectedAIModel')
    if (saved) {
      try {
        const { modelId } = JSON.parse(saved)
        return modelId
      } catch (e) {
        // If JSON parse fails, fall back to direct value
        return saved
      }
    }

    // Final fallback
    return 'gpt-4o'
  }

  // Load conversation via AJAX
  loadConversation(event) {
    event.preventDefault()
    const conversationId = event.currentTarget.dataset.conversationId
    const title = event.currentTarget.dataset.homeChatTitleValue

    if (this.currentConversationId === conversationId) {
      return // Already loaded
    }

    this.currentConversationId = conversationId
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Loading conversation..."
    }

    // Mark current conversation as active
    this.updateActiveConversation(event.currentTarget)

    // Load conversation content
    fetch(`/conversations/${conversationId}/quick_show`, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.text()
    })
    .then(html => {
      // Let Turbo handle the response
      Turbo.renderStreamMessage(html)
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = ""
      }
    })
    .catch(error => {
      console.error('Error loading conversation:', error)
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Failed to load conversation"
      }
    })
  }

  // Send message (enhanced to work with sidebar)
  sendMessage(event) {
    const isFormEvent = event.target.tagName === 'FORM'
    const form = isFormEvent ? event.target : event.target.closest('form')

    if (!isFormEvent) {
      event.preventDefault()
    }

    return this.submit({ ...event, target: form, preventDefault: () => {} })
  }

  // Model selection
  selectModel(event) {
    this.selectedModel = event.target.value
    this.updateModelButtons(event.target)
  }

  // Edit conversation title
  editTitle(event) {
    event.preventDefault()
    event.stopPropagation()

    const conversationId = event.currentTarget.dataset.conversationId
    const titleElement = document.querySelector(`#conversation-title-${conversationId}`)

    if (!titleElement) return

    const currentTitle = titleElement.textContent.trim()
    const input = document.createElement('input')

    input.type = 'text'
    input.value = currentTitle
    input.className = 'w-full bg-gray-600 text-white text-sm px-2 py-1 rounded border-0 focus:ring-1 focus:ring-blue-500'

    // Replace title with input
    titleElement.innerHTML = ''
    titleElement.appendChild(input)
    input.focus()
    input.select()

    // Save on Enter or blur
    const saveTitle = () => {
      const newTitle = input.value.trim()
      if (newTitle && newTitle !== currentTitle) {
        this.updateConversationTitle(conversationId, newTitle)
      } else {
        titleElement.textContent = currentTitle
      }
    }

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        saveTitle()
      } else if (e.key === 'Escape') {
        titleElement.textContent = currentTitle
      }
    })

    input.addEventListener('blur', saveTitle)
  }

  // Delete conversation
  deleteConversation(event) {
    event.preventDefault()
    event.stopPropagation()

    const conversationId = event.currentTarget.dataset.conversationId
    const conversationTitle = event.currentTarget.closest('.conversation-item')?.querySelector('.conversation-title')?.textContent?.trim() || 'this conversation'

    if (!confirm(`Are you sure you want to delete "${conversationTitle}"? This action cannot be undone.`)) {
      return
    }

    // Disable the delete button to prevent double-clicks
    const deleteButton = event.currentTarget
    deleteButton.disabled = true
    deleteButton.classList.add('opacity-50', 'cursor-not-allowed')

    // Show loading state
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = 'Deleting conversation...'
    }

    // Get CSRF token
    const token = document.querySelector('[name="csrf-token"]')?.getAttribute('content')

    fetch(`/conversations/${conversationId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.text()
    })
    .then(html => {
      // Process Turbo Stream response
      Turbo.renderStreamMessage(html)

      // Handle navigation if we're currently viewing the deleted conversation
      if (this.currentConversationId === conversationId) {
        this.currentConversationId = null

        // If we're on the conversation show page, redirect to home
        if (window.location.pathname.includes(`/conversations/${conversationId}`)) {
          window.location.href = '/'
        }
      }

      // Clear status
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = ''
      }

      // Show success feedback
      this.showNotification(`"${conversationTitle}" has been deleted`, 'success')
    })
    .catch(error => {
      console.error('Error deleting conversation:', error)

      // Re-enable the delete button
      deleteButton.disabled = false
      deleteButton.classList.remove('opacity-50', 'cursor-not-allowed')

      // Show error message
      const errorMessage = error.message.includes('403') ?
        'You do not have permission to delete this conversation' :
        'Failed to delete conversation. Please try again.'

      if (this.hasStatusTarget) {
        this.statusTarget.textContent = errorMessage
        setTimeout(() => {
          this.statusTarget.textContent = ''
        }, 5000)
      } else {
        alert(errorMessage)
      }
    })
  }

  // Private helper methods
  updateActiveConversation(activeElement) {
    // Remove active state from all conversations
    document.querySelectorAll('.conversation-item').forEach(item => {
      item.classList.remove('bg-gray-700')
    })

    // Add active state to current conversation
    activeElement.classList.add('bg-gray-700')
  }

  updateConversationTitle(conversationId, newTitle) {
    fetch(`/conversations/${conversationId}/update_title`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: JSON.stringify({ title: newTitle })
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.text()
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error updating title:', error)
      // Revert to original title
      const titleElement = document.querySelector(`#conversation-title-${conversationId}`)
      if (titleElement) {
        titleElement.textContent = titleElement.dataset.originalTitle || 'Chat'
      }
    })
  }

  updateModelButtons(selectedInput) {
    // Remove selected class from all model buttons
    document.querySelectorAll('.model-selector').forEach(label => {
      label.classList.remove('selected')
      label.classList.remove('bg-blue-600', 'text-white', 'border-blue-500')
      label.classList.remove('bg-purple-600', 'border-purple-500')
      label.classList.add('border-gray-600', 'text-gray-300')
    })

    // Add selected class to current model
    const selectedLabel = selectedInput.nextElementSibling || selectedInput.previousElementSibling
    if (selectedLabel) {
      selectedLabel.classList.add('selected')
      selectedLabel.classList.remove('border-gray-600', 'text-gray-300')

      if (this.selectedModel.includes('claude')) {
        selectedLabel.classList.add('bg-purple-600', 'text-white', 'border-purple-500')
      } else {
        selectedLabel.classList.add('bg-blue-600', 'text-white', 'border-blue-500')
      }
    }
  }

  setupCharCounter() {
    const textareas = this.element.querySelectorAll('textarea')
    textareas.forEach(textarea => {
      textarea.addEventListener('input', () => {
        if (this.hasCharCountTarget) {
          const count = textarea.value.length
          this.charCountTarget.textContent = `${count} characters`

          if (count > 4000) {
            this.charCountTarget.classList.add('text-red-400')
          } else if (count > 3000) {
            this.charCountTarget.classList.add('text-yellow-400')
          } else {
            this.charCountTarget.classList.remove('text-red-400', 'text-yellow-400')
          }
        }
      })
    })
  }

  // Show notification to user
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 px-4 py-3 rounded-lg shadow-lg z-50 transform transition-all duration-300 ${
      type === 'success' ? 'bg-green-600 text-white' :
      type === 'error' ? 'bg-red-600 text-white' :
      'bg-blue-600 text-white'
    }`

    notification.innerHTML = `
      <div class="flex items-center space-x-2">
        <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          ${type === 'success' ?
            '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>' :
            type === 'error' ?
            '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>' :
            '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'
          }
        </svg>
        <span class="text-sm font-medium">${message}</span>
      </div>
    `

    // Add to page
    document.body.appendChild(notification)

    // Animate in
    requestAnimationFrame(() => {
      notification.classList.add('translate-x-0')
      notification.classList.remove('translate-x-full')
    })

    // Auto remove after 4 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      notification.classList.remove('translate-x-0')

      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }, 4000)

    // Allow click to dismiss
    notification.addEventListener('click', () => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    })
  }
}