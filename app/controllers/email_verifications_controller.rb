class EmailVerificationsController < ApplicationController
  skip_before_action :require_complete_profile
  
  def show
    @user = User.find_by(verification_token: params[:token])
    
    if @user.nil?
      redirect_to root_path, alert: "Geçersiz onay linki."
      return
    end
    
    if @user.email_verified?
      redirect_to root_path, notice: "E-posta adresiniz zaten onaylanmış."
      return
    end
    
    if @user.verification_token_expired?
      redirect_to new_email_verification_path, alert: "Onay linki süresi dolmuş. Yeni bir onay e-postası gönderin."
      return
    end
    
    @user.verify_email!
    session[:user_id] = @user.id
    redirect_to profile_edit_path, notice: "E-posta adresiniz başarıyla onaylandı! Şimdi profilinizi tamamlayın."
  end
  
  def new
    # Yeni onay e-postası gönderme formu
  end
  
  def create
    @user = User.find_by(email_address: params[:email])
    
    if @user.nil?
      redirect_to new_email_verification_path, alert: "Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı."
      return
    end
    
    if @user.email_verified?
      redirect_to root_path, notice: "E-posta adresiniz zaten onaylanmış."
      return
    end
    
    unless @user.can_resend_verification?
      redirect_to new_email_verification_path, alert: "Yeni onay e-postası göndermek için 5 dakika beklemelisiniz."
      return
    end
    
    @user.generate_verification_token
    @user.save!
    
    UserMailer.email_verification(@user).deliver_now
    
    redirect_to new_email_verification_path, notice: "Onay e-postası gönderildi. E-posta kutunuzu kontrol edin."
  end
end