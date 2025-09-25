class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:create, :destroy]

  # POST /users/:user_id/follow
  def create
    if Current.user.follow(@user)
      # Takip edildiğinde bildirim oluştur
      NotificationService.create_and_broadcast(
        user: @user,
        message: "#{Current.user.username} started following you",
        notifiable: Current.user.active_follows.find_by(followed: @user)
      )
      
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user)) }
        format.turbo_stream
        format.json { render json: { status: 'followed', followers_count: @user.followers_count } }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), alert: 'Unable to follow user') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "Unable to follow user" }) }
        format.json { render json: { error: 'Unable to follow user' }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/:user_id/follow
  def destroy
    Current.user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_back(fallback_location: user_profile_path(@user)) }
      format.turbo_stream
      format.json { render json: { status: 'unfollowed', followers_count: @user.followers_count } }
    end
  end

  # GET /:username/followers
  def followers
    @user = User.find_by!(username: params[:username])
    @followers = @user.followers.includes(:team).limit(50)
    @following = @user.following.includes(:team).limit(50)
    @tab = params[:tab] || 'followers'
    
    respond_to do |format|
      format.html { render :index }
      format.turbo_stream
    end
  end

  # GET /:username/following
  def following
    @user = User.find_by!(username: params[:username])
    @followers = @user.followers.includes(:team).limit(50)
    @following = @user.following.includes(:team).limit(50)
    @tab = params[:tab] || 'following'
    
    respond_to do |format|
      format.html { render :index }
      format.turbo_stream
    end
  end

  # GET /:username/follows (new unified endpoint)
  def index
    @user = User.find_by!(username: params[:username])
    
    # Pagination için pagy kullan
    case params[:tab]
    when 'following'
      @pagy, @following = pagy(@user.following.includes(:team), items: 20)
      @followers = @user.followers.includes(:team).limit(20)
    when 'tribun'
      # Aynı takım taraftarları
      if @user.team.present?
        @pagy, @tribun_users = pagy(@user.followers.joins(:team).where(teams: { id: @user.team.id }).includes(:team), items: 20)
      else
        @pagy, @tribun_users = pagy(User.none, items: 20)
      end
      @followers = @user.followers.includes(:team).limit(20)
      @following = @user.following.includes(:team).limit(20)
    when 'ezeli_rakipler'
      # Rakip takım taraftarları
      if @user.rival_team.present?
        @pagy, @ezeli_rakipler = pagy(@user.followers.joins(:team).where(teams: { id: @user.rival_team.id }).includes(:team), items: 20)
      else
        @pagy, @ezeli_rakipler = pagy(User.none, items: 20)
      end
      @followers = @user.followers.includes(:team).limit(20)
      @following = @user.following.includes(:team).limit(20)
    else # 'followers'
      @pagy, @followers = pagy(@user.followers.includes(:team), items: 20)
      @following = @user.following.includes(:team).limit(20)
    end
    
    @tab = params[:tab] || 'followers'
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def authenticate_user!
    redirect_to new_session_path unless Current.user
  end
end