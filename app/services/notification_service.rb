class NotificationService
  def self.create_and_broadcast(user:, notifiable:, message:, title: nil)
    notification = user.notifications.create!(
      notifiable: notifiable,
      message: message
    )

    # Broadcast to user's notification channel
    ActionCable.server.broadcast(
      "notifications_#{user.id}",
      {
        type: 'new_notification',
        notification: {
          id: notification.id,
          title: title,
          message: message,
          created_at: notification.created_at,
          notifiable_type: notification.notifiable_type,
          notifiable_id: notification.notifiable_id
        },
        unread_count: user.notifications.unread.count
      }
    )

    notification
  end

  def self.mark_as_read(notification)
    notification.mark_as_read!
    
    # Broadcast updated unread count
    ActionCable.server.broadcast(
      "notifications_#{notification.user_id}",
      {
        type: 'notification_read',
        unread_count: notification.user.notifications.unread.count
      }
    )
  end

  def self.broadcast_unread_count(user)
    ActionCable.server.broadcast(
      "notifications_#{user.id}",
      {
        type: 'unread_count_update',
        unread_count: user.notifications.unread.count
      }
    )
  end
end