import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  vote(event) {
    event.preventDefault()

    const form = event.target.closest('form')
    const formData = new FormData(form)

    // Disable all voting buttons to prevent double-voting
    this.disableVoting(true)

    // Submit the vote
    fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.getAttribute('content')
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.text()
    })
    .then(html => {
      // Let Turbo handle the response to update the UI
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error submitting vote:', error)
      this.disableVoting(false) // Re-enable if there's an error
      alert('Failed to submit vote. Please try again.')
    })
  }

  disableVoting(disabled) {
    const votingContainer = this.element.closest('[id^="vote-buttons-"]')
    if (!votingContainer) return

    const buttons = votingContainer.querySelectorAll('button, input[type="submit"]')
    buttons.forEach(button => {
      button.disabled = disabled
      if (disabled) {
        button.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        button.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    })
  }
}