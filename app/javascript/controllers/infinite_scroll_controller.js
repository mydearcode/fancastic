import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { url: String }

  initialize() {
    this.intersectionObserver = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadMore()
        }
      })
    }, { threshold: 0.5 })
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
    const nextPage = this.paginationTarget.querySelector("a[rel='next']")
    if (nextPage) {
      // Show loading indicator
      this.paginationTarget.innerHTML = '<div class="flex justify-center"><button class="px-4 py-2 bg-blue-600 text-white rounded-full text-sm font-medium">Loading more posts...</button></div>'
      
      // Add a 5 second delay to make it easier to see the loading process
      setTimeout(() => {
        fetch(nextPage.href, {
          headers: {
            Accept: "text/vnd.turbo-stream.html"
          }
        })
      }, 5000)
    }
  }
}