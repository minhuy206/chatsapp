import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "conversationList"]
  static values = { collapsed: Boolean }

  connect() {
    this.originalConversations = []
    this.cacheConversations()
  }

  // Toggle sidebar visibility for mobile
  toggleSidebar() {
    this.collapsedValue = !this.collapsedValue
    this.updateSidebarState()
  }

  // Search conversations
  search(event) {
    const query = event.target.value.toLowerCase().trim()

    if (query === "") {
      this.showAllConversations()
    } else {
      this.filterConversations(query)
    }
  }

  // Private methods
  updateSidebarState() {
    const sidebar = this.element

    if (this.collapsedValue) {
      sidebar.classList.add("hidden", "md:flex")
      sidebar.classList.remove("w-80")
      sidebar.classList.add("w-0")
    } else {
      sidebar.classList.remove("hidden", "w-0")
      sidebar.classList.add("w-80")
    }
  }

  cacheConversations() {
    const conversationItems = this.conversationListTarget.querySelectorAll('.conversation-item')
    this.originalConversations = Array.from(conversationItems).map(item => ({
      element: item,
      title: item.querySelector('.conversation-title')?.textContent?.toLowerCase() || '',
      lastMessage: item.querySelector('.last-message')?.textContent?.toLowerCase() || ''
    }))
  }

  filterConversations(query) {
    this.originalConversations.forEach(({ element, title, lastMessage }) => {
      const matches = title.includes(query) || lastMessage.includes(query)

      if (matches) {
        element.style.display = 'block'
        this.highlightMatch(element, query)
      } else {
        element.style.display = 'none'
      }
    })
  }

  showAllConversations() {
    this.originalConversations.forEach(({ element }) => {
      element.style.display = 'block'
      this.removeHighlight(element)
    })
  }

  highlightMatch(element, query) {
    const titleEl = element.querySelector('.conversation-title')
    const messageEl = element.querySelector('.last-message')

    if (titleEl && titleEl.textContent.toLowerCase().includes(query)) {
      this.addHighlight(titleEl, query)
    }

    if (messageEl && messageEl.textContent.toLowerCase().includes(query)) {
      this.addHighlight(messageEl, query)
    }
  }

  addHighlight(element, query) {
    const text = element.textContent
    const regex = new RegExp(`(${query})`, 'gi')
    const highlightedText = text.replace(regex, '<mark class="bg-yellow-300 text-gray-900 rounded px-1">$1</mark>')
    element.innerHTML = highlightedText
  }

  removeHighlight(element) {
    const titleEl = element.querySelector('.conversation-title')
    const messageEl = element.querySelector('.last-message')

    if (titleEl) {
      titleEl.innerHTML = titleEl.textContent
    }

    if (messageEl) {
      messageEl.innerHTML = messageEl.textContent
    }
  }
}