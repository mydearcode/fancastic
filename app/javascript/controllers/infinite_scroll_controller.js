import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { url: String, page: { type: Number, default: 2 } }

  initialize() {
    this.setupObserver()
  }
  
  setupObserver() {
    this.loading = false
    this.finished = false
    
    // Create a new observer each time to ensure clean state
    this.intersectionObserver = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.loading && !this.finished) {
          this.loadMore()
        }
      })
    }, { rootMargin: '200px' })
  }

  connect() {
    // Reset state on connect (happens when tabs change)
    this.setupObserver()
    
    if (this.hasPaginationTarget) {
      this.intersectionObserver.observe(this.paginationTarget)
    }
  }

  disconnect() {
    if (this.hasPaginationTarget) {
      this.intersectionObserver.unobserve(this.paginationTarget)
    }
    
    // Clean up the observer
    this.intersectionObserver.disconnect()
  }

  loadMore() {
    // Check if we have a URL value to fetch and we're not already loading
    if (this.hasUrlValue && this.urlValue && !this.loading) {
      // Set loading state to prevent multiple requests
      this.loading = true
      
      // Construct the URL with the current page
      const url = new URL(this.urlValue, window.location.origin)
      
      fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })
      .then(response => response.text())
      .then(html => {
        // Check if we got an empty response or no more pages
        if (!html.includes('turbo-stream') || html.includes('pagination"></div>')) {
          this.finished = true
        } else {
          Turbo.renderStreamMessage(html)
        }
      })
      .catch(error => {
        console.error("Error loading more posts:", error)
      })
      .finally(() => {
        // Reset loading state after request completes
        this.loading = false
      })
    }
  }
}