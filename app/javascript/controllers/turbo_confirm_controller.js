import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Turbo confirm olaylarını dinle
    document.addEventListener('turbo:confirm-start', this.handleConfirmStart.bind(this))
    document.addEventListener('turbo:confirm-end', this.handleConfirmEnd.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:confirm-start', this.handleConfirmStart.bind(this))
    document.removeEventListener('turbo:confirm-end', this.handleConfirmEnd.bind(this))
  }

  handleConfirmStart(event) {
    // Confirm dialog açıldığında
  }

  handleConfirmEnd(event) {
    // Confirm dialog kapatıldığında tüm dropdown'ları kapat
    this.closeAllDropdowns()
  }

  closeAllDropdowns() {
    const allDropdowns = document.querySelectorAll('[data-controller*="dropdown"]')
    allDropdowns.forEach(dropdown => {
      const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
      if (controller && controller.hasMenuTarget && !controller.menuTarget.classList.contains('hidden')) {
        controller.close()
      }
    })
  }
}