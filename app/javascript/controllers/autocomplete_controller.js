import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String, minLength: { type: Number, default: 2 } }

  connect() {
    this.timeout = null
    this.currentRequest = null
    this.hideResults()
  }

  disconnect() {
    this.clearTimeout()
    this.abortRequest()
  }

  search() {
    const query = this.inputTarget.value.trim()
    
    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    this.clearTimeout()
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300) // 300ms debounce
  }

  performSearch(query) {
    this.abortRequest()
    
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('q', query)
    url.searchParams.set('autocomplete', 'true')
    
    this.currentRequest = fetch(url, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.displayResults(data)
    })
    .catch(error => {
      if (error.name !== 'AbortError') {
        console.error('Autocomplete error:', error)
      }
    })
    .finally(() => {
      this.currentRequest = null
    })
  }

  displayResults(data) {
    if (!data.users || data.users.length === 0) {
      this.hideResults()
      return
    }

    let html = '<div class="absolute top-full left-0 right-0 bg-gray-900 border border-gray-700 rounded-lg mt-1 shadow-lg z-50 max-h-60 overflow-y-auto">'
    
    data.users.forEach(user => {
      html += `
        <div class="flex items-center p-3 hover:bg-gray-800 cursor-pointer border-b border-gray-700 last:border-b-0" data-action="click->autocomplete#selectUser" data-username="${user.username}">
          <div class="flex-shrink-0 w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center mr-3">
            <span class="text-sm font-medium text-white">${user.username.charAt(0).toUpperCase()}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-white truncate">
              ${user.full_name || user.username}
            </p>
            <p class="text-xs text-gray-400 truncate">@${user.username}</p>
          </div>
        </div>
      `
    })
    
    html += '</div>'
    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  selectUser(event) {
    const username = event.currentTarget.dataset.username
    this.inputTarget.value = username
    this.hideResults()
    
    // Trigger search form submission
    const form = this.inputTarget.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }

  hideResults() {
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.classList.add('hidden')
  }

  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }

  clearTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  abortRequest() {
    if (this.currentRequest) {
      this.currentRequest.abort()
      this.currentRequest = null
    }
  }

  // Hide results when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}