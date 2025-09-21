class BlocksController < ApplicationController
  before_action :set_user, only: [:create, :destroy]

  def index
    @blocked_users = Current.user.blocked_users.includes(:team)
    @pagy, @blocked_users = pagy(@blocked_users, items: 20)
  end

  def create
    if Current.user.block(@user)
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), notice: "#{@user.username} has been blocked.") }
        format.json { render json: { status: 'blocked', message: 'User blocked successfully' } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("block_button_#{@user.id}", partial: 'shared/unblock_button', locals: { user: @user }) }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), alert: "Unable to block user.") }
        format.json { render json: { error: 'Unable to block user' }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if Current.user.unblock(@user)
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), notice: "#{@user.username} has been unblocked.") }
        format.json { render json: { status: 'unblocked', message: 'User unblocked successfully' } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("block_button_#{@user.id}", partial: 'shared/block_button', locals: { user: @user }) }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: user_profile_path(@user), alert: "Unable to unblock user.") }
        format.json { render json: { error: 'Unable to unblock user' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to root_path, alert: "User not found." }
      format.json { render json: { error: 'User not found' }, status: :not_found }
    end
  end
end