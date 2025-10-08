import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, text: String }

  connect() {
    // Share controller is ready
  }

  sharePost(event) {
    event.preventDefault()
    event.stopPropagation()
    
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