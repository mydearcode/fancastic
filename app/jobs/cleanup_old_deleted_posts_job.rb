class CleanupOldDeletedPostsJob < ApplicationJob
  queue_as :default

  def perform
    # 30 günden eski soft deleted postları bul
    cutoff_date = 30.days.ago
    old_deleted_posts = Post.deleted.where('deleted_at < ?', cutoff_date)
    
    Rails.logger.info "CleanupOldDeletedPostsJob: Found #{old_deleted_posts.count} posts to permanently delete"
    
    # Her post için kalıcı silme işlemi
    deleted_count = 0
    old_deleted_posts.find_each do |post|
      begin
        # İlişkili verileri de temizle
        post.likes.destroy_all
        post.replies.update_all(in_reply_to_post_id: nil)
        post.reposts.destroy_all
        post.quotes.update_all(quote_of_post_id: nil)
        
        # Post'u kalıcı olarak sil
        post.destroy
        deleted_count += 1
        
        Rails.logger.debug "CleanupOldDeletedPostsJob: Permanently deleted post ID #{post.id}"
      rescue => e
        Rails.logger.error "CleanupOldDeletedPostsJob: Failed to delete post ID #{post.id}: #{e.message}"
      end
    end
    
    Rails.logger.info "CleanupOldDeletedPostsJob: Successfully deleted #{deleted_count} posts"
  end
end
