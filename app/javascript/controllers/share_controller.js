import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, text: String, image: String }

  connect() {
    // Share controller is ready
  }

  sharePost(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const shareData = {
      title: 'Fancastic Post',
      text: this.textValue,
      url: this.urlValue
    }

    // Add image if available and supported
    if (this.imageValue && navigator.canShare) {
      // For Web Share API Level 2 (files support)
      fetch(this.imageValue)
        .then(response => response.blob())
        .then(blob => {
          const file = new File([blob], 'image.jpg', { type: blob.type })
          const shareDataWithFile = {
            ...shareData,
            files: [file]
          }
          
          if (navigator.canShare(shareDataWithFile)) {
            return navigator.share(shareDataWithFile)
          } else {
            return navigator.share(shareData)
          }
        })
        .catch(() => {
          // Fallback to sharing without image
          if (navigator.share) {
            navigator.share(shareData)
          } else {
            this.fallbackShare()
          }
        })
        .then(() => {
          // Shared successfully
        })
        .catch((error) => {
          if (error.name !== 'AbortError') {
            console.error('Error sharing:', error);
            this.fallbackShare();
          }
        })
    } else if (navigator.share) {
      navigator.share(shareData).then(() => {
        // Shared successfully
      }).catch((error) => {
        // Only show error if it's not a user cancellation
        if (error.name !== 'AbortError') {
          console.error('Error sharing:', error);
          this.fallbackShare();
        }
        // If user canceled, do nothing (silent fail)
      });
    } else {
      this.fallbackShare();
    }
  }

  share() {
    if (navigator.share) {
      navigator.share({
        title: 'Fancastic Post',
        text: this.textValue,
        url: this.urlValue
      }).then(() => {
        // Shared successfully
      }).catch((error) => {
        // Only show error if it's not a user cancellation
        if (error.name !== 'AbortError') {
          console.error('Error sharing:', error);
          this.fallbackShare();
        }
        // If user canceled, do nothing (silent fail)
      });
    } else {
      this.fallbackShare();
    }
  }

  fallbackShare() {
    // Check if document is focused before trying to copy
    if (!document.hasFocus()) {
      // Show a user-friendly message instead of trying to copy
      this.showShareMessage();
      return;
    }

    // Fallback to copying URL to clipboard
    navigator.clipboard.writeText(this.urlValue).then(() => {
      this.showShareMessage('Link copied to clipboard!');
    }).catch((error) => {
      console.error('Error copying to clipboard:', error);
      this.showShareMessage('Unable to copy link. Please copy manually: ' + this.urlValue);
    });
  }

  showShareMessage(message = 'Share this post: ' + this.urlValue) {
    // Create a simple notification
    const notification = document.createElement('div');
    notification.className = 'fixed top-4 right-4 bg-blue-600 text-white px-4 py-2 rounded-lg shadow-lg z-50 max-w-sm';
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.style.opacity = '0';
        notification.style.transition = 'opacity 0.3s';
        setTimeout(() => {
          if (notification.parentNode) {
            document.body.removeChild(notification);
          }
        }, 300);
      }
    }, 3000);
  }
}