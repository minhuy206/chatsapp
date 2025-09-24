import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    const element = this.element
    element.style.height = 'auto'
    element.style.height = Math.min(element.scrollHeight, 200) + 'px'
  }
}