class PostsController < ApplicationController
  before_action :require_authentication
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                 .order(created_at: :desc)
                 .limit(50)
    @post = Post.new
  end

  def show
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
    
    # Simple like implementation - in a real app you'd have a likes table
    Current.user.perform_action('like', @post)
    redirect_back(fallback_location: root_path, notice: 'Post liked!')
  end
  
  def repost
    unless Current.user.can_perform_action?('repost')
      redirect_back(fallback_location: root_path, alert: 'Not enough energy to repost.')
      return
    end
    
    repost = Current.user.posts.create!(
      repost_of_post: @post,
      visibility: 'public'
    )
    
    Current.user.perform_action('repost', @post)
    redirect_back(fallback_location: root_path, notice: 'Post reposted!')
  end
  
  def quote
    unless Current.user.can_perform_action?('quote')
      redirect_back(fallback_location: root_path, alert: 'Not enough energy to quote this post.')
      return
    end
    
    if request.post?
      # Handle quote post creation
      @quote_post = Current.user.posts.build(post_params.merge(quote_of_post: @post))
      
      if @quote_post.save
        Current.user.perform_action('quote', @post)
        redirect_to root_path, notice: 'Quote posted successfully!'
      else
        render :quote, status: :unprocessable_entity
      end
    else
      # Show quote form
      @quote_post = Current.user.posts.build(quote_of_post: @post)
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:text, :image_url, :visibility, :in_reply_to_post_id, :repost_of_post_id, :quote_of_post_id)
  end
end
