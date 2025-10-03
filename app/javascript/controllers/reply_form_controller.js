import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "counter"]
  static values = { maxLength: { type: Number, default: 280 } }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    if (!this.hasTextareaTarget || !this.hasCounterTarget) return
    
    const currentLength = this.textareaTarget.value.length
    const maxLength = this.maxLengthValue
    
    this.counterTarget.textContent = `${currentLength}/${maxLength}`
    
    // Change color based on character count
    this.counterTarget.classList.remove('text-gray-500', 'text-yellow-400', 'text-red-400')
    
    if (currentLength > maxLength * 0.9) {
      this.counterTarget.classList.add('text-red-400')
    } else if (currentLength > maxLength * 0.7) {
      this.counterTarget.classList.add('text-yellow-400')
    } else {
      this.counterTarget.classList.add('text-gray-500')
    }
    
    // Auto-expand functionality
    this.autoExpand()
    
    // Disable submit button if over limit
    const submitButton = this.element.querySelector('input[type="submit"], button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = currentLength > maxLength
      if (currentLength > maxLength) {
        submitButton.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        submitButton.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
  }

  autoExpand() {
    const textarea = this.textareaTarget
    
    // Reset height to auto to get the correct scrollHeight
    textarea.style.height = 'auto'
    
    // Calculate the number of lines
    const lineHeight = parseInt(window.getComputedStyle(textarea).lineHeight)
    const minRows = parseInt(textarea.dataset.minRows) || 1
    const maxRows = parseInt(textarea.dataset.maxRows) || 6
    
    // Calculate new height based on content
    const newHeight = Math.min(
      Math.max(textarea.scrollHeight, lineHeight * minRows),
      lineHeight * maxRows
    )
    
    textarea.style.height = newHeight + 'px'
  }

  focus() {
    if (this.textareaTarget.rows === 1) {
      this.textareaTarget.rows = 2
      this.autoExpand()
    }
  }

  paste() {
    setTimeout(() => this.updateCounter(), 0)
  }
}