import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "image", "prevBtn", "nextBtn", "counter"]
  static values = { 
    images: Array,
    currentIndex: Number
  }

  connect() {
    this.currentIndexValue = 0
    this.imagesValue = []
  }

  openViewer(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const clickedImage = event.currentTarget
    const imageUrl = clickedImage.dataset.imageUrl
    
    // Find all images in the same post
    const postElement = clickedImage.closest('[data-controller*="image-viewer"]')
    if (postElement) {
      const allImages = postElement.querySelectorAll('img[data-action*="click->image-viewer#openViewer"]')
      this.imagesValue = Array.from(allImages).map(img => img.dataset.imageUrl)
      this.currentIndexValue = this.imagesValue.indexOf(imageUrl)
    } else {
      this.imagesValue = [imageUrl]
      this.currentIndexValue = 0
    }
    
    this.showModal()
    this.updateImage()
    this.updateNavigation()
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
  }

  closeViewer(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    this.hideModal()
    
    // Restore body scroll
    document.body.style.overflow = ''
  }

  nextImage(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.currentIndexValue < this.imagesValue.length - 1) {
      this.currentIndexValue++
      this.updateImage()
      this.updateNavigation()
    }
  }

  prevImage(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.currentIndexValue > 0) {
      this.currentIndexValue--
      this.updateImage()
      this.updateNavigation()
    }
  }

  handleKeydown(event) {
    switch(event.key) {
      case 'Escape':
        this.closeViewer()
        break
      case 'ArrowLeft':
        if (this.currentIndexValue > 0) {
          this.prevImage(event)
        }
        break
      case 'ArrowRight':
        if (this.currentIndexValue < this.imagesValue.length - 1) {
          this.nextImage(event)
        }
        break
    }
  }

  handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      this.closeViewer()
    }
  }

  showModal() {
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.classList.add('flex')
    
    // Add event listeners
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  hideModal() {
    this.modalTarget.classList.add('hidden')
    this.modalTarget.classList.remove('flex')
    
    // Remove event listeners
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  updateImage() {
    if (this.hasImageTarget && this.imagesValue[this.currentIndexValue]) {
      this.imageTarget.src = this.imagesValue[this.currentIndexValue]
      this.imageTarget.alt = `Image ${this.currentIndexValue + 1} of ${this.imagesValue.length}`
    }
  }

  updateNavigation() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndexValue + 1} / ${this.imagesValue.length}`
    }
    
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.style.display = this.currentIndexValue > 0 ? 'block' : 'none'
    }
    
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.style.display = this.currentIndexValue < this.imagesValue.length - 1 ? 'block' : 'none'
    }
  }
}