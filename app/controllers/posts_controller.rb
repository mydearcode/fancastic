class PostsController < ApplicationController
  before_action :require_authentication
  before_action :set_post, only: [:show, :edit, :update, :destroy, :like, :repost, :reply, :quote]

  def index
    @tab = params[:tab] || 'following'
    # Store the current tab in session to persist between requests
    session[:current_tab] = @tab
    
    posts_query = case @tab
    when 'following'
      # Posts from users the current user follows
      Post.joins("INNER JOIN follows ON follows.followed_id = posts.user_id")
          .where(follows: { follower_id: Current.user.id })
          .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
          .order(created_at: :desc)
    when 'teammates'
      # Posts from users with the same team as current user
      team_id = Current.user.team_id
      Post.joins(:user)
          .where(users: { team_id: team_id })
          .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
          .order(created_at: :desc)
    when 'popular'
      # Popular posts based on likes count
      Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
          .left_joins(:likes)
          .group('posts.id')
          .order('COUNT(likes.id) DESC, posts.created_at DESC')
    when 'archrival'
      # Posts from users with rival teams
      rival_team_ids = Current.user.rival_teams.pluck(:id)
      if rival_team_ids.present?
        Post.joins(:user)
            .where(users: { team_id: rival_team_ids })
            .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
            .order(created_at: :desc)
      else
        # If no rival teams selected, show empty result
        Post.none
      end
    else
      # Default to all posts if tab is invalid
      Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
          .order(created_at: :desc)
    end
    
    # Filter out posts from blocked users
    blocked_user_ids = Current.user.blocked_user_ids + Current.user.blocking_user_ids
    posts_query = posts_query.where.not(user_id: blocked_user_ids) if blocked_user_ids.any?
          
    @pagy, @posts = pagy(posts_query, items: 5)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
    
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
    # Check if user is suspended
    if Current.user.suspended?
      redirect_to root_path, alert: "Your account has been suspended. Reason: #{Current.user.suspend_reason.humanize}"
      return
    end
    
    # Check if user has enough energy to post
    unless Current.user.can_perform_action?('post')
      redirect_to root_path, alert: 'Not enough energy to create a post. Wait for energy to restore or try a smaller action.'
      return
    end
    
    @post = Current.user.posts.build(post_params)
    
    if @post.save
      # Consume energy for posting
      Current.user.perform_action('post', @post)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path, notice: 'Post created successfully!' }
      end
    else
      @posts = Post.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                   .order(created_at: :desc)
                   .limit(50)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("post_form", partial: "posts/form", locals: { post: @post }) }
        format.html { render :index, status: :unprocessable_entity }
      end
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
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: 'Post deleted successfully!' }
    end
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
          respond_to do |format|
            format.html { redirect_to posts_path, notice: 'Post quoted successfully!' }
            format.turbo_stream do
              # First, clear the modal
              render turbo_stream: [
                turbo_stream.replace("quote_modal", ""),
                turbo_stream.prepend("posts", partial: "posts/post", locals: { post: @quote_post })
              ]
            end
          end
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
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: 'Not enough energy to reply to this post.') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Not enough energy to reply to this post." }) }
      end
      return
    end
    
    # Handle reply creation
    @reply_post = Current.user.posts.build(post_params.merge(in_reply_to_post_id: @post.id, visibility: 'everyone'))
    
    if @reply_post.save
      Current.user.perform_action('reply', @post)
      respond_to do |format|
        format.html { redirect_to post_path(@post), notice: 'Reply posted successfully!' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to post_path(@post), alert: 'Failed to post reply. Please try again.' }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("reply_form", partial: "posts/reply_form", locals: { post: @post, reply_post: @reply_post }) }
      end
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
    params.require(:post).permit(:text, :image, :visibility, :in_reply_to_post_id, :repost_of_post_id, :quote_of_post_id)
  end
  
  def quote_params
    params.require(:post).permit(:text, :image, :visibility)
  end
end
