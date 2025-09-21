class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_teams, only: [:edit, :update]
  before_action :set_user, only: [:show, :show_user]
  
  def show
    @user = Current.user
    @is_own_profile = true
    load_user_content
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show_user
    @user = User.find(params[:id])
    @is_own_profile = @user == Current.user
    load_user_content
    
    respond_to do |format|
      format.html { render :show }
      format.turbo_stream { render "show" }
    end
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    
    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to profile_path, notice: "Profile updated successfully." }
        format.turbo_stream { redirect_to profile_path, notice: "Profile updated successfully." }
      end
    else
      set_teams
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def set_user
    @tab = params[:tab] || 'posts'
  end
  
  def load_user_content
    case @tab
    when 'posts'
      posts_query = @user.posts.where(in_reply_to_post_id: nil)
                         .includes(:user, :repost_of_post, :quote_of_post)
                         .order(created_at: :desc)
    when 'replies'
      posts_query = @user.posts.where.not(in_reply_to_post_id: nil)
                         .includes(:user, :in_reply_to_post)
                         .order(created_at: :desc)
    when 'likes'
      posts_query = Post.joins(:likes)
                        .where(likes: { user_id: @user.id })
                        .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                        .order('likes.created_at DESC')
    else
      posts_query = @user.posts.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                         .order(created_at: :desc)
    end
    
    @pagy, @posts = pagy(posts_query, items: 5)
  end
  
  def user_params
    params.require(:user).permit(:full_name, :username, :team_id, :message_privacy, :profile_picture, :cover_picture, rival_team_ids: [])
  end
  
  def set_teams
    @teams = Team.includes(:league, :country).order("countries.name, leagues.name, teams.name")
  end
end
