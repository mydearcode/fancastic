class Api::UsersController < ApplicationController
  before_action :require_authentication
  
  def show
    @user = User.find_by!(username: params[:username])
    
    # Check if user is blocked
    if Current.user.blocked?(@user) || Current.user.blocked_by?(@user)
      render json: { error: 'User not accessible' }, status: :forbidden
      return
    end
    
    # Check if user is suspended
    if @user.suspended?
      render json: { error: 'User suspended' }, status: :forbidden
      return
    end
    
    # Get user stats
    followers_count = @user.followers.count
    following_count = @user.following.count
    posts_count = @user.posts.count
    
    # Check if current user is following this user
    is_following = Current.user.following?(@user)
    is_current_user = @user == Current.user
    
    # Profile picture URL
    profile_picture_url = @user.profile_picture.attached? ? url_for(@user.profile_picture) : nil
    
    user_data = {
      username: @user.username,
      full_name: @user.full_name,
      bio: @user.bio,
      location: @user.location,
      website: @user.website,
      birth_date: @user.birth_date&.strftime("%B %d, %Y"),
      age: @user.age,
      followers_count: followers_count,
      following_count: following_count,
      posts_count: posts_count,
      is_following: is_following,
      is_current_user: is_current_user,
      profile_picture_url: profile_picture_url,
      team: @user.team ? {
        name: @user.team.name,
        symbol_slug: @user.team.symbol_slug,
        color_primary: @user.team.color_primary,
        color_secondary: @user.team.color_secondary
      } : nil
    }
    
    render json: user_data
    
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
end