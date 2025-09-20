module Admin
  class AdminController < ApplicationController
    before_action :require_authentication
    before_action :require_admin
    
    layout 'admin'
    
    def index
      @countries_count = Country.count
      @leagues_count = League.count
      @teams_count = Team.count
      @users_count = User.count
      @posts_count = Post.count
      @reports_count = Report.count
    end
    
    private
    
    def require_admin
    redirect_to root_path, alert: 'Access denied.' unless Current.user&.admin?
  end
  end
end