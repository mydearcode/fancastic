import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "fileInput", "previewContainer"]

  connect() {
    this.createPreviewContainer()
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Add paste event listener to textarea
    if (this.hasTextareaTarget) {
      this.textareaTarget.addEventListener('paste', this.handlePaste.bind(this))
    }

    // Add file input change listener
    if (this.hasFileInputTarget) {
      this.fileInputTarget.addEventListener('change', this.handleFileInputChange.bind(this))
    }
  }

  handlePaste(event) {
    const items = event.clipboardData.items
    
    for (let i = 0; i < items.length; i++) {
      const item = items[i]
      
      if (item.type.indexOf('image') !== -1) {
        event.preventDefault()
        
        const file = item.getAsFile()
        if (file) {
          this.handleImageFile(file)
        }
        break
      }
    }
  }

  handleFileInputChange(event) {
    if (event.target.files && event.target.files.length > 0) {
      this.showImagePreview()
      this.showSuccess(`${event.target.files.length} resim seçildi!`)
    }
  }

  handleImageFile(file) {
    // Validate file size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      this.showError('Resim 10MB\'dan küçük olmalıdır')
      return
    }
    
    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      this.showError('Lütfen JPEG, PNG, GIF veya WebP formatında resim yükleyin')
      return
    }
    
    if (this.hasFileInputTarget) {
      // Get existing files if any
      const existingFiles = Array.from(this.fileInputTarget.files || [])
      
      // Create a new FileList with existing files plus the pasted file
      const dataTransfer = new DataTransfer()
      existingFiles.forEach(file => dataTransfer.items.add(file))
      dataTransfer.items.add(file)
      this.fileInputTarget.files = dataTransfer.files
      
      // Trigger change event
      this.fileInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
      
      // Show preview
      this.showImagePreview()
      
      // Show success message
      this.showSuccess('Resim başarıyla yapıştırıldı!')
    }
  }

  createPreviewContainer() {
    if (!this.hasPreviewContainerTarget && this.hasTextareaTarget) {
      const previewContainer = document.createElement('div')
      previewContainer.className = 'image-preview-container mt-3 hidden'
      previewContainer.setAttribute('data-image-paste-target', 'previewContainer')
      
      // Insert after textarea
      this.textareaTarget.parentNode.insertBefore(previewContainer, this.textareaTarget.nextSibling)
    }
  }

  showImagePreview() {
    if (!this.hasPreviewContainerTarget || !this.hasFileInputTarget) return
    
    // Get all current files from the file input
    const allFiles = Array.from(this.fileInputTarget.files || [])
    
    // Clear existing preview and rebuild with all files
    this.previewContainerTarget.innerHTML = ''
    
    if (allFiles.length > 0) {
      const previewGrid = document.createElement('div')
      previewGrid.className = 'grid gap-2'
      
      // Set grid columns based on number of images
      if (allFiles.length === 1) {
        previewGrid.className += ' grid-cols-1'
      } else if (allFiles.length === 2) {
        previewGrid.className += ' grid-cols-2'
      } else if (allFiles.length <= 4) {
        previewGrid.className += ' grid-cols-2'
      } else {
        previewGrid.className += ' grid-cols-2'
      }
      
      allFiles.forEach((currentFile, index) => {
        const reader = new FileReader()
        reader.onload = (e) => {
          const imagePreview = document.createElement('div')
          imagePreview.className = 'relative inline-block'
          
          // For more than 4 images, show overlay on the 4th image
          const showOverlay = allFiles.length > 4 && index === 3
          
          imagePreview.innerHTML = `
            <img src="${e.target.result}" 
                 class="w-full h-32 object-cover rounded-lg border border-gray-700 ${showOverlay ? 'brightness-50' : ''}" 
                 alt="Resim önizleme ${index + 1}">
            ${showOverlay ? `
              <div class="absolute inset-0 flex items-center justify-center text-white font-bold text-lg">
                +${allFiles.length - 4}
              </div>
            ` : ''}
            <button type="button" 
                    class="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold transition-colors"
                    data-action="click->image-paste#removeImage"
                    data-image-index="${index}">
              ×
            </button>
            <div class="mt-1 text-xs text-gray-400 truncate">
              ${currentFile.name} (${this.formatFileSize(currentFile.size)})
            </div>
          `
          
          previewGrid.appendChild(imagePreview)
          
          // Show only first 4 images
          if (index >= 4) {
            imagePreview.style.display = 'none'
          }
        }
        reader.readAsDataURL(currentFile)
      })
      
      this.previewContainerTarget.appendChild(previewGrid)
      this.previewContainerTarget.classList.remove('hidden')
    } else {
      this.previewContainerTarget.classList.add('hidden')
    }
  }

  removeImage(event) {
    const button = event.target
    const imageIndex = parseInt(button.dataset.imageIndex)
    
    if (this.hasFileInputTarget && this.fileInputTarget.files.length > 0) {
      // Get current files and remove the specified index
      const currentFiles = Array.from(this.fileInputTarget.files)
      currentFiles.splice(imageIndex, 1)
      
      // Update file input with remaining files
      const dataTransfer = new DataTransfer()
      currentFiles.forEach(file => dataTransfer.items.add(file))
      this.fileInputTarget.files = dataTransfer.files
      
      // Trigger change event
      this.fileInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
      
      // Refresh preview with remaining files
      if (currentFiles.length > 0) {
        this.showImagePreview()
      } else {
        // No files left, hide preview
        this.previewContainerTarget.classList.add('hidden')
        this.previewContainerTarget.innerHTML = ''
      }
    }
  }

  clearAllImages() {
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ''
      this.fileInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }
    
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.classList.add('hidden')
      this.previewContainerTarget.innerHTML = ''
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  showError(message) {
    // Create or update error message
    let errorDiv = document.querySelector('.image-paste-error')
    
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.className = 'image-paste-error fixed top-4 right-4 bg-red-600 text-white px-4 py-2 rounded-lg shadow-lg z-50'
      document.body.appendChild(errorDiv)
    }
    
    errorDiv.textContent = message
    errorDiv.style.display = 'block'
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
      errorDiv.style.display = 'none'
    }, 3000)
  }

  showSuccess(message) {
    // Create or update success message
    let successDiv = document.querySelector('.image-paste-success')
    
    if (!successDiv) {
      successDiv = document.createElement('div')
      successDiv.className = 'image-paste-success fixed top-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50'
      document.body.appendChild(successDiv)
    }
    
    successDiv.textContent = message
    successDiv.style.display = 'block'
    
    // Auto-hide after 2 seconds
    setTimeout(() => {
      successDiv.style.display = 'none'
    }, 2000)
  }
}