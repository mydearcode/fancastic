import { Controller } from "@hotwired/stimulus"

// Selectively disable Turbo prefetching for post links
export default class extends Controller {
  connect() {
    // Find all links within posts that don't need prefetching
    this.disablePrefetchingOnPostLinks()
    
    // Set up a mutation observer to handle dynamically added links
    this.setupMutationObserver()
  }
  
  disablePrefetchingOnPostLinks() {
    // Target links in post cards and modals that cause unnecessary server requests
    const postLinks = document.querySelectorAll('.post-card a, .post-modal a')
    postLinks.forEach(link => {
      // Skip links that need immediate loading (like action buttons)
      if (!link.classList.contains('needs-prefetch')) {
        link.setAttribute('data-turbo-prefetch', 'false')
      }
    })
  }
  
  setupMutationObserver() {
    // Create a mutation observer to handle dynamically added links
    const observer = new MutationObserver((mutations) => {
      mutations.forEach(mutation => {
        if (mutation.type === 'childList') {
          mutation.addedNodes.forEach(node => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              // Check if the added node is within a post
              if (node.closest('.post-card, .post-modal')) {
                // Find all links within the added node
                const links = node.querySelectorAll('a')
                links.forEach(link => {
                  if (!link.classList.contains('needs-prefetch')) {
                    link.setAttribute('data-turbo-prefetch', 'false')
                  }
                })
              }
            }
          })
        }
      })
    })
    
    // Start observing the document
    observer.observe(document.body, { childList: true, subtree: true })
  }
}