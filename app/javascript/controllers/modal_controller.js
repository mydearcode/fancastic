import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container"]
  
  connect() {
    // Make sure modal is hidden on connect
    if (this.element.id === "post-modal") {
      this.element.classList.add("hidden")
    }
    
    // Add event listener for ESC key to close modal
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
  }

  disconnect() {
    // Remove event listener when controller disconnects
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
  }

  handleKeyDown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  open(event) {
    if (event) event.preventDefault()
    
    const modalId = event.currentTarget.dataset.modalTarget
    const modal = document.getElementById(modalId)
    
    if (modal) {
      modal.classList.remove('hidden')
      modal.style.display = "flex"
      document.body.classList.add('overflow-hidden')
    }
  }

  close(event) {
    if (event) event.preventDefault()
    
    this.element.classList.add('hidden')
    this.element.style.display = "none"
    document.body.classList.remove('overflow-hidden')
  }

  // Close when clicking outside the modal content
  clickOutside(event) {
    // Only close if clicking the background overlay, not the modal content
    if (event.target === this.element) {
      this.close()
    }
  }
}