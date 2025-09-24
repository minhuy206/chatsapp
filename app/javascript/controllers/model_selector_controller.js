import { Controller } from "@hotwired/stimulus"

// Model Selector Controller for AI chat interface
// Manages model selection UI and persists user preferences
export default class extends Controller {
  static targets = ["dropdown", "button", "selectedModel", "hiddenField", "modelOption"]

  connect() {
    this.loadSelectedModel()
    this.setupClickOutside()
  }

  disconnect() {
    this.removeClickOutside()
  }

  // Toggle dropdown visibility
  toggle() {
    const isOpen = this.dropdownTarget.classList.contains("show")
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  // Open dropdown
  open() {
    this.dropdownTarget.classList.add("show")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  // Close dropdown
  close() {
    this.dropdownTarget.classList.remove("show")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // Handle model selection
  selectModel(event) {
    const modelButton = event.currentTarget
    const modelId = modelButton.dataset.model
    const modelName = modelButton.dataset.name
    const provider = modelButton.dataset.provider

    // Update UI
    this.updateSelectedModel(modelId, modelName, provider)

    // Update hidden form field
    this.updateHiddenField(modelId)

    // Save to localStorage for persistence
    this.saveSelectedModel(modelId, modelName, provider)

    // Close dropdown
    this.close()

    // Trigger custom event for other components
    this.dispatch("modelChanged", {
      detail: {
        modelId: modelId,
        modelName: modelName,
        provider: provider
      }
    })
  }

  // Update the displayed selected model
  updateSelectedModel(modelId, modelName, provider) {
    const providerIcon = this.getProviderIcon(provider)
    const providerColor = this.getProviderColor(provider)

    this.selectedModelTarget.innerHTML = `
      <div class="flex items-center space-x-2">
        <span class="${providerColor}">${providerIcon}</span>
        <span class="text-white font-medium">${modelName}</span>
        <svg class="w-4 h-4 text-gray-400 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
      </div>
    `

    // Update active state on model options
    this.modelOptionTargets.forEach(option => {
      if (option.dataset.model === modelId) {
        option.classList.add("active")
        option.setAttribute("aria-selected", "true")
      } else {
        option.classList.remove("active")
        option.setAttribute("aria-selected", "false")
      }
    })
  }

  // Load previously selected model from localStorage
  loadSelectedModel() {
    const saved = localStorage.getItem('selectedAIModel')
    if (saved) {
      try {
        const { modelId, modelName, provider } = JSON.parse(saved)
        this.updateSelectedModel(modelId, modelName, provider)
        this.updateHiddenField(modelId)
      } catch (e) {
        // Fallback to default if localStorage is corrupted
        this.setDefaultModel()
      }
    } else {
      this.setDefaultModel()
    }
  }

  // Save selected model to localStorage
  saveSelectedModel(modelId, modelName, provider) {
    const modelData = { modelId, modelName, provider }
    localStorage.setItem('selectedAIModel', JSON.stringify(modelData))
  }

  // Set default model (GPT-4o)
  setDefaultModel() {
    this.updateSelectedModel('gpt-4o', 'GPT-4o', 'openai')
    this.updateHiddenField('gpt-4o')
    this.saveSelectedModel('gpt-4o', 'GPT-4o', 'openai')
  }

  // Update hidden field helper
  updateHiddenField(modelId) {
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = modelId
      console.log('✅ Model updated via target:', modelId)
    } else {
      // Fallback: find the hidden field within the form
      const hiddenField = this.element.querySelector('input[name="ai_model"]')
      if (hiddenField) {
        hiddenField.value = modelId
        console.log('✅ Model updated via fallback:', modelId)
      } else {
        console.error('❌ Could not find hidden field to update')
      }
    }
  }

  // Get provider icon
  getProviderIcon(provider) {
    const icons = {
      'openai': '🤖',
      'anthropic': '🧠'
    }
    return icons[provider] || '🤖'
  }

  // Get provider color class
  getProviderColor(provider) {
    const colors = {
      'openai': 'text-green-400',
      'anthropic': 'text-purple-400'
    }
    return colors[provider] || 'text-green-400'
  }

  // Setup click outside to close dropdown
  setupClickOutside() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.boundClickOutside)
  }

  // Remove click outside listener
  removeClickOutside() {
    if (this.boundClickOutside) {
      document.removeEventListener('click', this.boundClickOutside)
    }
  }

  // Handle clicks outside the dropdown
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  // Handle keyboard navigation
  handleKeydown(event) {
    const isOpen = this.dropdownTarget.classList.contains("show")

    switch (event.key) {
      case 'Escape':
        if (isOpen) {
          this.close()
          this.buttonTarget.focus()
        }
        break
      case 'ArrowDown':
        if (!isOpen) {
          event.preventDefault()
          this.open()
        }
        break
      case 'Enter':
      case ' ':
        if (!isOpen) {
          event.preventDefault()
          this.toggle()
        }
        break
    }
  }
}