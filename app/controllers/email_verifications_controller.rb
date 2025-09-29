class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_complete_profile
  
  # Rate limiting to prevent abuse
  rate_limit to: 5, within: 15.minutes, only: :show, with: -> { redirect_to root_path, alert: "Çok fazla deneme yaptınız. 15 dakika sonra tekrar deneyin." }
  rate_limit to: 3, within: 5.minutes, only: :create, with: -> { redirect_to new_email_verification_path, alert: "Çok fazla e-posta gönderme isteği. 5 dakika sonra tekrar deneyin." }
  
  def show
    @user = User.find_by(verification_token: params[:token])
    
    # Debug logs only in development
    if Rails.env.development?
      Rails.logger.info "=== EMAIL VERIFICATION DEBUG ==="
      Rails.logger.info "Token: #{params[:token]}"
      Rails.logger.info "User found: #{@user.present?}"
    end
    
    if @user.nil?
      Rails.logger.info "User not found with token" if Rails.env.development?
      redirect_to root_path, alert: "Geçersiz onay linki."
      return
    end
    
    if Rails.env.development?
      Rails.logger.info "User: #{@user.username} (#{@user.email_address})"
      Rails.logger.info "Email already verified: #{@user.email_verified?}"
    end
    
    if @user.email_verified?
      Rails.logger.info "Email already verified, redirecting to root" if Rails.env.development?
      redirect_to root_path, notice: "E-posta adresiniz zaten onaylanmış."
      return
    end
    
    Rails.logger.info "Token expired: #{@user.verification_token_expired?}" if Rails.env.development?
    
    if @user.verification_token_expired?
      Rails.logger.info "Token expired, redirecting to new verification" if Rails.env.development?
      redirect_to new_email_verification_path, alert: "Onay linki süresi dolmuş. Yeni bir onay e-postası gönderin."
      return
    end
    
    if Rails.env.development?
      Rails.logger.info "Verifying email..."
    end
    @user.verify_email!
    Rails.logger.info "Email verified successfully" if Rails.env.development?
    
    if Rails.env.development?
      Rails.logger.info "Starting new session..."
    end
    start_new_session_for @user
    if Rails.env.development?
      Rails.logger.info "Session started. Current.session: #{Current.session&.id}"
      Rails.logger.info "Current.user: #{Current.user&.username}"
    end
    
    redirect_to profile_edit_path, notice: "E-posta adresiniz başarıyla onaylandı! Şimdi profilinizi tamamlayın."
  end
  
  def new
    # Yeni onay e-postası gönderme formu
  end
  
  def create
    @user = User.find_by(email_address: email_verification_params[:email])
    
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

  private

  def email_verification_params
    params.permit(:email)
  end
end