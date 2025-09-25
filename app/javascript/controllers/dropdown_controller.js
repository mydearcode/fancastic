import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundClose = this.closeOnOutsideClick.bind(this)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // Close all other dropdowns first
    this.closeAllOtherDropdowns()
    
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.boundClose)
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClose)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeAllOtherDropdowns() {
    const allDropdowns = document.querySelectorAll('[data-controller*="dropdown"]')
    allDropdowns.forEach(dropdown => {
      if (dropdown !== this.element) {
        const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
        if (controller && controller.hasMenuTarget && !controller.menuTarget.classList.contains('hidden')) {
          controller.close()
        }
      }
    })
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

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}