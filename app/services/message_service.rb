class MessageService
  def self.broadcast_unread_count(user)
    ActionCable.server.broadcast(
      "messages_#{user.id}",
      {
        type: 'unread_count_update',
        unread_messages_count: user.unread_messages_count
      }
    )
  end
end