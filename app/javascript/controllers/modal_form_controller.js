import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal-form"
export default class extends Controller {
  closeModal() {
    // Find the post modal
    const modal = document.getElementById('post-modal')
    
    if (modal) {
      // Add hidden class
      modal.classList.add('hidden')
      // Hide with display property
      modal.style.display = 'none'
      // Remove overflow-hidden from body
      document.body.classList.remove('overflow-hidden')
    }
  }
}