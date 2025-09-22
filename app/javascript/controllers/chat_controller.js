import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messagesContainer"]

  connect() {
    this.scrollToBottom()

    // Listen for turbo:frame-load events to scroll after new messages
    document.addEventListener("turbo:frame-load", this.scrollToBottom.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.scrollToBottom.bind(this))
  }

  scrollToBottom() {
    if (this.hasMessagesContainerTarget) {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    }
  }

  // Called when new messages are added via Turbo Streams
  messagesTargetConnected() {
    this.scrollToBottom()
  }
}