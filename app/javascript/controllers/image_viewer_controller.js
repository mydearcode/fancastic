import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]
  
  connect() {
    this.currentIndex = 0
    this.images = Array.from(this.element.querySelectorAll('[data-image-viewer-target="image"]'))
    this.setupKeyboardNavigation()
    this.setupGlobalModalHandlers()
  }

  disconnect() {
    this.removeKeyboardNavigation()
    this.removeGlobalModalHandlers()
  }

  showImage(event) {
    const clickedImage = event.currentTarget
    this.currentIndex = this.images.indexOf(clickedImage)
    
    if (this.currentIndex === -1) return
    
    this.showModal()
  }

  // Alias for showImage to match the action name used in templates
  openViewer(event) {
    this.showImage(event)
  }

  showModal() {
    const modal = document.getElementById('image-viewer-modal')
    const modalImage = document.querySelector('#image-viewer-modal img')
    const counter = document.querySelector('#image-viewer-modal .image-counter')
    const prevBtn = document.querySelector('#image-viewer-modal .prev-btn')
    const nextBtn = document.querySelector('#image-viewer-modal .next-btn')
    
    if (!modal || !modalImage) return
    
    // Set this controller as the active one
    window.activeImageViewer = this
    
    this.updateModalImage()
    modal.classList.remove('hidden')
    modal.style.display = 'flex'
    document.body.style.overflow = 'hidden'
    
    // Update navigation buttons visibility
    if (prevBtn) prevBtn.style.display = this.images.length > 1 ? 'flex' : 'none'
    if (nextBtn) nextBtn.style.display = this.images.length > 1 ? 'flex' : 'none'
  }

  updateModalImage() {
    const modalImage = document.querySelector('#image-viewer-modal img')
    const counter = document.querySelector('#image-viewer-modal .image-counter')
    
    if (!modalImage || this.currentIndex < 0 || this.currentIndex >= this.images.length) return
    
    const currentImage = this.images[this.currentIndex]
    const imageSrc = currentImage.src || currentImage.dataset.src
    
    modalImage.src = imageSrc
    modalImage.alt = currentImage.alt || `Resim ${this.currentIndex + 1}`
    
    if (counter) {
      counter.textContent = `${this.currentIndex + 1} / ${this.images.length}`
    }
  }

  nextImage() {
    if (this.images.length <= 1) return
    
    this.currentIndex = (this.currentIndex + 1) % this.images.length
    this.updateModalImage()
  }

  prevImage() {
    if (this.images.length <= 1) return
    
    this.currentIndex = this.currentIndex === 0 ? this.images.length - 1 : this.currentIndex - 1
    this.updateModalImage()
  }

  closeViewer() {
    const modal = document.getElementById('image-viewer-modal')
    if (modal) {
      modal.classList.add('hidden')
      modal.style.display = 'none'
      document.body.style.overflow = ''
      window.activeImageViewer = null
    }
  }

  handleKeydown(event) {
    const modal = document.getElementById('image-viewer-modal')
    if (!modal || modal.classList.contains('hidden') || window.activeImageViewer !== this) return
    
    switch(event.key) {
      case 'Escape':
        this.closeViewer()
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.prevImage()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nextImage()
        break
    }
  }

  setupKeyboardNavigation() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.keydownHandler)
  }

  removeKeyboardNavigation() {
    if (this.keydownHandler) {
      document.removeEventListener('keydown', this.keydownHandler)
    }
  }

  setupGlobalModalHandlers() {
    // Global modal close handler
    this.modalCloseHandler = (event) => {
      if (window.activeImageViewer === this) {
        this.closeViewer()
      }
    }

    // Global modal navigation handlers
    this.modalPrevHandler = (event) => {
      if (window.activeImageViewer === this) {
        this.prevImage()
      }
    }

    this.modalNextHandler = (event) => {
      if (window.activeImageViewer === this) {
        this.nextImage()
      }
    }

    // Global modal backdrop click handler
    this.modalBackdropHandler = (event) => {
      if (window.activeImageViewer === this && event.target.id === 'image-viewer-modal') {
        this.closeViewer()
      }
    }

    // Add event listeners to global modal elements
    const closeBtn = document.querySelector('#image-viewer-modal .close-btn')
    const prevBtn = document.querySelector('#image-viewer-modal .prev-btn')
    const nextBtn = document.querySelector('#image-viewer-modal .next-btn')
    const modal = document.getElementById('image-viewer-modal')

    if (closeBtn) closeBtn.addEventListener('click', this.modalCloseHandler)
    if (prevBtn) prevBtn.addEventListener('click', this.modalPrevHandler)
    if (nextBtn) nextBtn.addEventListener('click', this.modalNextHandler)
    if (modal) modal.addEventListener('click', this.modalBackdropHandler)
  }

  removeGlobalModalHandlers() {
    const closeBtn = document.querySelector('#image-viewer-modal .close-btn')
    const prevBtn = document.querySelector('#image-viewer-modal .prev-btn')
    const nextBtn = document.querySelector('#image-viewer-modal .next-btn')
    const modal = document.getElementById('image-viewer-modal')

    if (closeBtn && this.modalCloseHandler) closeBtn.removeEventListener('click', this.modalCloseHandler)
    if (prevBtn && this.modalPrevHandler) prevBtn.removeEventListener('click', this.modalPrevHandler)
    if (nextBtn && this.modalNextHandler) nextBtn.removeEventListener('click', this.modalNextHandler)
    if (modal && this.modalBackdropHandler) modal.removeEventListener('click', this.modalBackdropHandler)

    if (window.activeImageViewer === this) {
      window.activeImageViewer = null
    }
  }
}