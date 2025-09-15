class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:create, :destroy]

  # POST /users/:user_id/follow
  def create
    if Current.user.follow(@user)
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user)) }
        format.json { render json: { status: 'followed', followers_count: @user.followers_count } }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), alert: 'Unable to follow user') }
        format.json { render json: { error: 'Unable to follow user' }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/:user_id/follow
  def destroy
    Current.user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_back(fallback_location: user_profile_path(@user)) }
      format.json { render json: { status: 'unfollowed', followers_count: @user.followers_count } }
    end
  end

  # GET /users/:user_id/followers
  def followers
    @user = User.find(params[:user_id])
    @followers = @user.followers.includes(:team).limit(50)
  end

  # GET /users/:user_id/following
  def following
    @user = User.find(params[:user_id])
    @following = @user.following.includes(:team).limit(50)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def authenticate_user!
    redirect_to new_session_path unless Current.user
  end
end