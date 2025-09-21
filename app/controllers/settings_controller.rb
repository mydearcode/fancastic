class SettingsController < ApplicationController
  before_action :require_authentication

  def index
    @blocked_users = Current.user.blocked_users.includes(:team)
  end

  def blocked_users
    @blocked_users = Current.user.blocked_users.includes(:team)
  end

  def privacy
    # Privacy settings page
  end

  def notifications
    # Notification settings page
  end
end