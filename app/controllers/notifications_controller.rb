class NotificationsController < ApplicationController
  before_action :require_authentication
  include Pagy::Backend

  def index
    # Sadece post ile ilgili bildirimleri al - mesaj bildirimlerini hariç tut
    notifications = Current.user.notifications
                                .includes(:notifiable)
                                .where.not(notifiable_type: 'Message')
                                .recent
    
    # Bildirimleri post_id'ye göre grupla
    grouped_notifications = {}
    
    notifications.each do |notification|
      # Post ID'sini belirle
      post_id = case notification.notifiable_type
      when 'Post'
        notification.notifiable.id
      when 'Like'
        notification.notifiable.post_id
      when 'Follow'
        # Follow bildirimleri için post ID yok, unique key kullan
        "#{notification.notifiable_type}_#{notification.id}"
      else
        # Diğer bildirim türleri için post ilişkisini kontrol et
        if notification.notifiable.respond_to?(:post_id)
          notification.notifiable.post_id
        elsif notification.notifiable.respond_to?(:post)
          notification.notifiable.post&.id
        else
          # Post olmayan bildirimler için unique key oluştur
          "#{notification.notifiable_type}_#{notification.id}"
        end
      end
      
      # Bildirim türünü belirle (like, reply, repost, etc.)
      notification_type = if notification.message.include?('liked')
        'like'
      elsif notification.message.include?('replied')
        'reply'
      elsif notification.message.include?('reposted')
        'repost'
      elsif notification.message.include?('mentioned')
        'mention'
      elsif notification.message.include?('quoted')
        'quote'
      elsif notification.message.include?('following')
        'follow'
      else
        'other'
      end
      
      # Gruplama anahtarı: follow bildirimleri için tek grup, diğerleri için post_id + type
      if notification_type == 'follow'
        group_key = "follow_follow"  # Tüm follow bildirimlerini tek grupta topla
      else
        group_key = "#{post_id}_#{notification_type}"
      end
      
      if grouped_notifications[group_key]
        grouped_notifications[group_key][:notifications] << notification
        grouped_notifications[group_key][:count] += 1
        # En son bildirimi güncelle (en yeni tarih)
        if notification.created_at > grouped_notifications[group_key][:latest_notification].created_at
          grouped_notifications[group_key][:latest_notification] = notification
        end
      else
        # Post özetini veya reply özetini al (eğer post varsa)
        post_summary = nil
        if post_id.is_a?(Integer) && notification_type != 'follow'
          begin
            post = Post.find(post_id)
            if notification_type == 'reply'
              # Reply bildirimleri için reply metninin özetini al
              reply_post = notification.notifiable
              if reply_post.is_a?(Post) && reply_post.text.present?
                post_summary = reply_post.text.length > 140 ? "#{reply_post.text[0..136]}..." : reply_post.text
              end
            else
              # Diğer bildirimler için orijinal post metnini al
              if post.text.present?
                post_summary = post.text.length > 140 ? "#{post.text[0..136]}..." : post.text
              end
            end
          rescue ActiveRecord::RecordNotFound
            post_summary = nil
          end
        end
        
        grouped_notifications[group_key] = {
          post_id: post_id,
          notification_type: notification_type,
          notifications: [notification],
          latest_notification: notification,
          count: 1,
          post_summary: post_summary
        }
      end
    end
    
    # Grupları tarihe göre sırala (en yeni önce)
    grouped_array = grouped_notifications.values.sort_by { |group| group[:latest_notification].created_at }.reverse
    
    # Sayfalama için manuel olarak slice kullan
    page = params[:page]&.to_i || 1
    items_per_page = 20
    start_index = (page - 1) * items_per_page
    end_index = start_index + items_per_page - 1
    
    @grouped_notifications = grouped_array[start_index..end_index] || []
    @total_pages = (grouped_array.size.to_f / items_per_page).ceil
    @current_page = page
    
    # Mark all notifications as read when user visits the page
    Current.user.notifications.unread.update_all(read_at: Time.current)
    
    # Broadcast updated unread count (should be 0 now)
    NotificationService.broadcast_unread_count(Current.user)
  end

  def mark_as_read
    @notification = Current.user.notifications.find(params[:id])
    NotificationService.mark_as_read(@notification)
    
    redirect_back(fallback_location: notifications_path)
  end

  def mark_all_as_read
    Current.user.notifications.unread.update_all(read_at: Time.current)
    NotificationService.broadcast_unread_count(Current.user)
    
    redirect_to notifications_path, notice: 'All notifications marked as read.'
  end
end