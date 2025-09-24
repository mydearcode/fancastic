import consumer from "channels/consumer"

consumer.subscriptions.create("MessagesChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to messages channel");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Disconnected from messages channel");
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received message update:", data);
    
    // Update messages badge when unread count changes
    if (data.type === 'unread_count_update' && data.unread_messages_count !== undefined) {
      this.updateMessagesBadge(data.unread_messages_count);
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
  }
});