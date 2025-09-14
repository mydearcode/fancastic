class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_teams, only: [:edit, :update]
  
  def show
    @user = Current.user
    @is_own_profile = true
  end

  def show_user
    @user = User.find(params[:id])
    @is_own_profile = @user == Current.user
    render :show
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      set_teams
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:username, :team_id, :message_privacy)
  end
  
  def set_teams
    @teams = Team.includes(:league, :country).order("countries.name, leagues.name, teams.name")
  end
end
