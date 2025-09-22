import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "selectedIcon", "selectedName", "selectedDescription"]

  static models = {
    "gpt-4o": {
      name: "GPT-4o",
      description: "Latest OpenAI model with enhanced multimodal capabilities",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-green-500 to-emerald-600",
      provider: "OpenAI"
    },
    "gpt-4": {
      name: "GPT-4",
      description: "Powerful reasoning and complex problem-solving capabilities",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-blue-500 to-indigo-600",
      provider: "OpenAI"
    },
    "gpt-3.5-turbo": {
      name: "GPT-3.5 Turbo",
      description: "Fast and efficient for everyday tasks and conversations",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-blue-400 to-purple-500",
      provider: "OpenAI"
    },
    "claude-3.5-sonnet": {
      name: "Claude 3.5 Sonnet",
      description: "Latest Claude model with enhanced reasoning and analysis",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-orange-500 to-red-500",
      provider: "Anthropic"
    },
    "claude-3-opus": {
      name: "Claude 3 Opus",
      description: "Most capable Claude model for complex reasoning tasks",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-purple-600 to-pink-600",
      provider: "Anthropic"
    },
    "claude-3-sonnet": {
      name: "Claude 3 Sonnet",
      description: "Balanced performance for most tasks and conversations",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-orange-400 to-red-500",
      provider: "Anthropic"
    },
    "claude-3-haiku": {
      name: "Claude 3 Haiku",
      description: "Fast and efficient for quick responses and simple tasks",
      icon: `<svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
      </svg>`,
      iconClass: "bg-gradient-to-br from-teal-500 to-cyan-600",
      provider: "Anthropic"
    }
  }

  connect() {
    // Load selected model from localStorage or default to gpt-4o
    const savedModel = localStorage.getItem('selectedAIModel') || 'gpt-4o'
    this.updateSelectedDisplay(savedModel)
    this.updateCheckmarks(savedModel)

    // Close modal on escape key
    document.addEventListener('keydown', this.handleEscape.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleEscape.bind(this))
  }

  openModal() {
    this.modalTarget.classList.remove('hidden', '-translate-x-full')
    this.modalTarget.classList.add('translate-x-0')
    this.backdropTarget.classList.remove('hidden')

    // Prevent body scroll
    document.body.style.overflow = 'hidden'
  }

  closeModal() {
    this.modalTarget.classList.remove('translate-x-0')
    this.modalTarget.classList.add('-translate-x-full')
    this.backdropTarget.classList.add('hidden')

    // Restore body scroll
    document.body.style.overflow = ''

    // Hide modal after animation
    setTimeout(() => {
      this.modalTarget.classList.add('hidden')
    }, 300)
  }

  selectModel(event) {
    const modelValue = event.currentTarget.dataset.model

    // Update display
    this.updateSelectedDisplay(modelValue)
    this.updateCheckmarks(modelValue)

    // Update form field
    this.updateFormField(modelValue)

    // Save to localStorage
    localStorage.setItem('selectedAIModel', modelValue)

    // Close modal
    this.closeModal()
  }

  updateSelectedDisplay(modelValue) {
    const modelData = this.constructor.models[modelValue]
    if (!modelData) return

    // Update icon
    this.selectedIconTarget.className = `w-6 h-6 ${modelData.iconClass} rounded-md flex items-center justify-center flex-shrink-0`
    this.selectedIconTarget.innerHTML = modelData.icon

    // Update text
    this.selectedNameTarget.textContent = modelData.name
    this.selectedDescriptionTarget.textContent = modelData.description
  }

  updateCheckmarks(selectedModel) {
    // Hide all checkmarks
    this.element.querySelectorAll('[data-check]').forEach(check => {
      check.style.opacity = '0'
    })

    // Show checkmark for selected model
    const selectedCheck = this.element.querySelector(`[data-check="${selectedModel}"]`)
    if (selectedCheck) {
      selectedCheck.style.opacity = '1'
    }
  }

  updateFormField(modelValue) {
    // Update any form field that needs the selected model
    const hiddenInput = document.querySelector('input[name="ai_model"]')
    if (hiddenInput) {
      hiddenInput.value = modelValue
    }

    // Also update the home chat controller's selected model if it exists
    const homeChatElement = document.querySelector('[data-controller*="home-chat"]')
    if (homeChatElement) {
      const homeChatController = this.application.getControllerForElementAndIdentifier(
        homeChatElement,
        'home-chat'
      )
      if (homeChatController) {
        homeChatController.selectedModel = modelValue
      }
    }
  }

  handleEscape(event) {
    if (event.key === 'Escape' && !this.modalTarget.classList.contains('hidden')) {
      this.closeModal()
    }
  }

  get selectedModel() {
    return localStorage.getItem('selectedAIModel') || 'gpt-4o'
  }
}