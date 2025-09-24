class MentionService
  def self.extract_mentions(text)
    return [] if text.blank?
    
    # @username pattern'ini bul
    mentions = text.scan(/@([a-zA-Z0-9_]+)/)
    usernames = mentions.flatten.uniq
    
    # Geçerli kullanıcıları bul
    User.where(username: usernames)
  end
  
  def self.create_mention_notifications(post, mentioned_users)
    mentioned_users.each do |mentioned_user|
      # Kendi kendini mention etmişse bildirim gönderme
      next if mentioned_user == post.user
      
      NotificationService.create_and_broadcast(
        user: mentioned_user,
        notifiable: post,
        message: "#{post.user.username} mentioned you in a post",
        title: "New Mention"
      )
    end
  end
  
  def self.process_mentions(post)
    mentioned_users = extract_mentions(post.text)
    create_mention_notifications(post, mentioned_users) if mentioned_users.any?
    mentioned_users
  end
end