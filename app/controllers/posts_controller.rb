class PostsController < ApplicationController
  before_action :require_authentication
  before_action :set_post, only: [:show, :edit, :update, :destroy, :like, :repost, :reply, :quote]

  def index
    @posts = Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                 .order(created_at: :desc)
                 .limit(50)
    @post = Post.new
  end

  def show
    @replies = @post.replies.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                    .order(created_at: :desc)
    @reply_post = Post.new(visibility: 'everyone')
  end

  def new
    @post = Current.user.posts.build
  end

  def create
    # Check if user has enough energy to post
    unless Current.user.can_perform_action?('post')
      redirect_to root_path, alert: 'Not enough energy to create a post. Wait for energy to restore or try a smaller action.'
      return
    end
    
    @post = Current.user.posts.build(post_params)
    
    if @post.save
      # Consume energy for posting
      Current.user.perform_action('post', @post)
      redirect_to root_path, notice: 'Post created successfully!'
    else
      @posts = Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                   .order(created_at: :desc)
                   .limit(50)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: 'Post updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to root_path, notice: 'Post deleted successfully!'
  end
  
  def like
    unless Current.user.can_perform_action?('like')
      redirect_back(fallback_location: root_path, alert: 'Not enough energy to like this post.')
      return
    end
    
    existing_like = @post.likes.find_by(user: Current.user)
    
    if existing_like
      # Unlike the post
      existing_like.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: 'Post unliked!') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_#{@post.id}", partial: 'posts/post', locals: { post: @post }) }
      end
    else
      # Like the post
      @post.likes.create!(user: Current.user)
      Current.user.perform_action('like', @post)
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: 'Post liked!') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_#{@post.id}", partial: 'posts/post', locals: { post: @post }) }
      end
    end
  end
  
  def repost
    unless Current.user.can_perform_action?('repost')
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: 'Not enough energy to repost.') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Not enough energy to repost." }) }
      end
      return
    end
    
    # Check if user already reposted this post
    existing_repost = Current.user.posts.find_by(repost_of_post: @post)
    
    if existing_repost
      # Remove the existing repost (unrepost)
      @existing_repost = existing_repost
      existing_repost.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: 'Repost removed successfully!') }
        format.turbo_stream { render :unrepost }
      end
    else
      # Create repost
      @repost = Current.user.posts.build(
        text: "", # Empty content for simple repost
        repost_of_post: @post,
        visibility: 'everyone'
      )
      
      if @repost.save
        Current.user.perform_action('repost', @post)
        respond_to do |format|
          format.html { redirect_back(fallback_location: root_path, notice: 'Post reposted successfully!') }
          format.turbo_stream { render :repost }
        end
      else
        error_message = @repost.errors.full_messages.first || 'Failed to repost.'
        respond_to do |format|
          format.html { redirect_back(fallback_location: root_path, alert: error_message) }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: error_message }) }
        end
      end
    end
  end
  
  def quote
    @post = Post.find(params[:id])
    
    if request.post?
      # Handle quote creation
      if Current.user.can_perform_action?('quote')
        @quote_post = Current.user.posts.build(quote_params)
        @quote_post.quote_of_post = @post
        
        if @quote_post.save
          Current.user.perform_action('quote')
          redirect_to posts_path, notice: 'Post quoted successfully!'
        else
          render :quote
        end
      else
        redirect_to posts_path, alert: 'Not enough energy to quote.'
      end
    else
      # Handle quote form display
      if Current.user.can_perform_action?('quote')
        @quote_post = Current.user.posts.build
      else
        redirect_to posts_path, alert: 'Not enough energy to quote.'
      end
    end
  end
  
  def reply
    @post = Post.find(params[:id])
    
    unless Current.user.can_perform_action?('reply')
      redirect_back(fallback_location: root_path, alert: 'Not enough energy to reply to this post.')
      return
    end
    
    # Handle reply creation
    @reply_post = Current.user.posts.build(post_params.merge(in_reply_to_post_id: @post.id, visibility: 'everyone'))
    
    if @reply_post.save
      Current.user.perform_action('reply', @post)
      redirect_to post_path(@post), notice: 'Reply posted successfully!'
    else
      redirect_to post_path(@post), alert: 'Failed to post reply. Please try again.'
    end
  end
  
  def quotes
    @post = Post.find(params[:id])
    @quotes = Post.includes(:user, :quote_of_post)
                  .where(quote_of_post: @post)
                  .order(created_at: :desc)
                  .limit(50)
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:text, :image_url, :visibility, :in_reply_to_post_id, :repost_of_post_id, :quote_of_post_id)
  end
  
  def quote_params
    params.require(:post).permit(:text, :visibility)
  end
end
