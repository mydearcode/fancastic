import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { url: String, page: { type: Number, default: 2 } }

  initialize() {
    this.intersectionObserver = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadMore()
        }
      })
    }, { rootMargin: '200px' })
  }

  connect() {
    if (this.hasPaginationTarget) {
      this.intersectionObserver.observe(this.paginationTarget)
    }
  }

  disconnect() {
    if (this.hasPaginationTarget) {
      this.intersectionObserver.unobserve(this.paginationTarget)
    }
  }

  loadMore() {
    // Check if we have a URL value to fetch
    if (this.hasUrlValue && this.urlValue) {
      // No loading indicator - silent loading
      
      // Construct the URL with the current page
      const url = new URL(this.urlValue, window.location.origin)
      
      fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
        this.pageValue++
      })
      .catch(error => {
        console.error("Error loading more posts:", error)
        // No error indicator
      })
    }
  }
}