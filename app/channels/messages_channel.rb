class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe user to their personal messages channel
    stream_from "messages_#{current_user.id}" if current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end