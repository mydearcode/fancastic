class SuspendedAccountsController < ApplicationController
  allow_unauthenticated_access only: [:show]
  
  def show
    # URL'den gelen username parametresine göre kullanıcıyı bul
    # Eğer username parametresi yoksa ve kullanıcı giriş yapmışsa Current.user'ı kullan
    if params[:username].present?
      @user = User.find_by(username: params[:username])
    else
      @user = Current.user
    end
    
    # Kullanıcı bulunamadıysa ana sayfaya yönlendir
    unless @user
      redirect_to root_path, alert: "User not found"
      return
    end
    
    # Kullanıcı suspend edilmemişse ana sayfaya yönlendir
    unless @user.suspended?
      redirect_to root_path, alert: "This account is not suspended"
      return
    end
    
    @suspend_reason = @user.suspend_reason
    @suspend_date = @user.suspend_date
  end
end