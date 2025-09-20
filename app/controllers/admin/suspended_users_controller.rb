module Admin
  class SuspendedUsersController < AdminController
    def index
      @suspended_users = User.where(suspended: true).order(suspend_date: :desc)
    end
    
    def unsuspend
      @user = User.find(params[:id])
      
      if @user.update(suspended: false, suspend_date: nil, suspend_reason: nil)
        # Kullanıcının en son suspension log kaydını bul ve güncelle
        suspension_log = UserSuspensionLog.where(user_id: @user.id, unsuspended_at: nil).order(suspended_at: :desc).first
        
        if suspension_log
          suspension_log.update(
            unsuspended_by_id: Current.user.id,
            unsuspended_at: Time.current
          )
        end
        
        redirect_to admin_suspended_users_path, notice: "#{@user.username} has been unsuspended successfully."
      else
        redirect_to admin_suspended_users_path, alert: "Failed to unsuspend user."
      end
    end
  end
end