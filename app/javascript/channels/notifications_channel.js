import consumer from "channels/consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to notifications channel");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Disconnected from notifications channel");
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received notification:", data);
    
    // Update notification badge
    this.updateNotificationBadge(data.unread_count);
    
    // Show notification toast if it's a new notification
    if (data.type === 'new_notification') {
      this.showNotificationToast(data.notification);
    }
  },

  updateNotificationBadge(count) {
    const badge = document.getElementById('notification-badge');
    const mobileBadge = document.getElementById('mobile-notification-badge');
    
    if (badge) {
      if (count > 0) {
        badge.textContent = count > 99 ? '99+' : count;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    }
    
    if (mobileBadge) {
      if (count > 0) {
        mobileBadge.textContent = count > 99 ? '99+' : count;
        mobileBadge.classList.remove('hidden');
      } else {
        mobileBadge.classList.add('hidden');
      }
    }
  },

  updateMessagesBadge(count) {
    const badge = document.getElementById('messages-badge');
    const mobileBadge = document.getElementById('mobile-messages-badge');
    
    if (badge) {
      if (count > 0) {
        badge.textContent = count > 99 ? '99+' : count;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    }
    
    if (mobileBadge) {
      if (count > 0) {
        mobileBadge.textContent = count > 99 ? '99+' : count;
        mobileBadge.classList.remove('hidden');
      } else {
        mobileBadge.classList.add('hidden');
      }
    }
  },

  showNotificationToast(notification) {
    // Create a simple toast notification
    const toast = document.createElement('div');
    toast.className = 'fixed top-4 right-4 bg-blue-600 text-white px-4 py-2 rounded-lg shadow-lg z-50 max-w-sm';
    toast.innerHTML = `
      <div class="flex items-center space-x-2">
        <div class="flex-1">
          <div class="font-medium">${notification.title || 'New Notification'}</div>
          <div class="text-sm opacity-90">${notification.message}</div>
        </div>
        <button onclick="this.parentElement.parentElement.remove()" class="text-white hover:text-gray-200">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `;
    
    document.body.appendChild(toast);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
      if (toast.parentElement) {
        toast.remove();
      }
    }, 5000);
  }
});
