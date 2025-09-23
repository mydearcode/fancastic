module Admin
  class PostsController < AdminController
    before_action :set_post, only: [:restore, :destroy]
    
    def index
      @deleted_posts = Post.unscoped.where.not(deleted_at: nil)
                          .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                          .order(deleted_at: :desc)
      @pagy, @deleted_posts = pagy(@deleted_posts, items: 20)
    end

    def restore
      @post.restore!
      respond_to do |format|
        format.html { redirect_to admin_posts_path, notice: 'Post restored successfully!' }
        format.turbo_stream
      end
    end

    def destroy
      @post.destroy # Kalıcı silme
      respond_to do |format|
        format.html { redirect_to admin_posts_path, notice: 'Post permanently deleted!' }
        format.turbo_stream
      end
    end
    
    private
    
    def set_post
      @post = Post.unscoped.where.not(deleted_at: nil).find(params[:id])
    end
  end
end
