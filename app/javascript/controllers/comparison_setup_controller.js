import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "status", "charCount"]

  connect() {
    this.updateUI()
    this.setupCharCounter()
  }

  selectModel(event) {
    const radio = event.target
    const side = radio.closest('.model-option').dataset.modelSide
    const container = radio.closest('.model-option').closest('div')

    // Update visual selection for this side
    this.updateModelSelection(container, radio)
    this.updateSubmitButton()
  }

  handleKeydown(event) {
    if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
      event.preventDefault()
      this.startComparison(event)
    }
  }

  startComparison(event) {
    const form = event.target.closest('form')
    const formData = new FormData(form)

    if (!this.validateForm(formData)) {
      return false
    }

    this.disableForm(true)
    this.statusTarget.textContent = 'Starting comparison...'

    return true // Allow form submission
  }

  // Private methods
  updateModelSelection(container, selectedRadio) {
    // Clear all selections in this container
    container.querySelectorAll('.model-option').forEach(option => {
      option.classList.remove('border-blue-500', 'border-purple-500', 'bg-blue-900/20', 'bg-purple-900/20')
      option.classList.add('border-gray-600')
      option.querySelector('.model-selected').classList.add('hidden')
    })

    // Highlight selected option
    const selectedOption = selectedRadio.closest('.model-option')
    const side = selectedOption.dataset.modelSide

    selectedOption.classList.remove('border-gray-600')
    if (side === 'a') {
      selectedOption.classList.add('border-blue-500', 'bg-blue-900/20')
    } else {
      selectedOption.classList.add('border-purple-500', 'bg-purple-900/20')
    }

    selectedOption.querySelector('.model-selected').classList.remove('hidden')
  }

  validateForm(formData) {
    const modelA = formData.get('comparison[model_a]')
    const modelB = formData.get('comparison[model_b]')
    const content = formData.get('comparison[content]')?.trim()

    if (!modelA) {
      this.showStatus('Please select Model A', 'error')
      return false
    }

    if (!modelB) {
      this.showStatus('Please select Model B', 'error')
      return false
    }

    if (modelA === modelB) {
      this.showStatus('Please select different models for comparison', 'error')
      return false
    }

    if (!content) {
      this.showStatus('Please enter a prompt', 'error')
      return false
    }

    return true
  }

  showStatus(message, type = 'info') {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.className = `text-xs ${
      type === 'error' ? 'text-red-400' :
      type === 'success' ? 'text-green-400' : 'text-gray-400'
    }`

    if (type === 'error') {
      setTimeout(() => {
        this.statusTarget.textContent = ''
      }, 5000)
    }
  }

  updateSubmitButton() {
    if (!this.hasSubmitButtonTarget) return

    const form = this.element.querySelector('form')
    const formData = new FormData(form)

    const modelA = formData.get('comparison[model_a]')
    const modelB = formData.get('comparison[model_b]')
    const content = formData.get('comparison[content]')?.trim()

    const isValid = modelA && modelB && modelA !== modelB && content

    this.submitButtonTarget.disabled = !isValid

    if (isValid) {
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    } else {
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  disableForm(disabled) {
    const form = this.element.querySelector('form')
    const inputs = form.querySelectorAll('input, textarea, button')

    inputs.forEach(input => {
      input.disabled = disabled
    })

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.textContent = disabled ? 'Starting...' : 'Start Comparison'
    }
  }

  updateUI() {
    this.updateSubmitButton()
  }

  setupCharCounter() {
    const textarea = this.element.querySelector('textarea')
    if (!textarea || !this.hasCharCountTarget) return

    textarea.addEventListener('input', () => {
      const count = textarea.value.length
      this.charCountTarget.textContent = `${count} characters`

      if (count > 4000) {
        this.charCountTarget.classList.add('text-red-400')
      } else if (count > 3000) {
        this.charCountTarget.classList.add('text-yellow-400')
        this.charCountTarget.classList.remove('text-red-400')
      } else {
        this.charCountTarget.classList.remove('text-red-400', 'text-yellow-400')
      }

      this.updateSubmitButton()
    })
  }
}