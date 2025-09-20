module Admin
  class UsersController < AdminController
    before_action :set_user, only: [:suspend, :unsuspend]
    
    def index
      @users = User.order(:username)
      @pagy, @users = pagy(@users, items: 20)
    end

    def search
      query = params[:query].to_s.strip
      
      if query.present?
        @users = User.where("username ILIKE ? OR email_address ILIKE ?", "%#{query}%", "%#{query}%")
                    .order(:username)
        @pagy, @users = pagy(@users, items: 20)
        
        if @users.empty?
          flash.now[:alert] = "No users found matching '#{query}'"
        end
      else
        redirect_to admin_users_path
        return
      end
      
      render :index
    end
    
    def suspend
      if @user.update(suspended: true, suspend_date: Date.today, suspend_reason: :moderator_action)
        # Log the suspension
        UserSuspensionLog.create(
          user: @user,
          suspended_by: Current.user,
          suspended_at: Time.current,
          suspend_reason: :moderator_action
        )
        redirect_to admin_users_path, notice: "#{@user.username} has been suspended successfully."
      else
        redirect_to admin_users_path, alert: "Failed to suspend user."
      end
    end
    
    def unsuspend
      if @user.update(suspended: false, suspend_date: nil, suspend_reason: nil)
        # Kullanıcının en son suspension log kaydını bul ve güncelle
        suspension_log = UserSuspensionLog.where(user_id: @user.id, unsuspended_at: nil).order(suspended_at: :desc).first
        
        if suspension_log
          suspension_log.update(
            unsuspended_by_id: Current.user.id,
            unsuspended_at: Time.current
          )
        end
        
        redirect_to admin_users_path, notice: "#{@user.username} has been unsuspended successfully."
      else
        redirect_to admin_users_path, alert: "Failed to unsuspend user."
      end
    end
    
    def suspension_logs
      @pagy, @logs = pagy(UserSuspensionLog.all.order(suspended_at: :desc), items: 20)
    end
    
    private
    
    def set_user
      @user = User.find(params[:id])
    end
  end
end