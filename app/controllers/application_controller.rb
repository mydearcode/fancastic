class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Askıya alınmış kullanıcıları kontrol etmek için before_action kullanıyoruz
  # Authentication modülünden sonra çalışması için prepend_before_action yerine before_action kullanıyoruz
  before_action :check_suspended_user, if: :authenticated?
  before_action :require_complete_profile, if: :authenticated?
  before_action :filter_blocked_content, if: :authenticated?
  
  private
  
  def check_suspended_user
    # Kullanıcı yoksa veya askıya alınmamışsa işlem yapma
    return unless Current.user&.suspended?
    
    # İzin verilen controller ve action'lar
    allowed = (controller_name == 'sessions' && action_name == 'destroy') || 
              controller_name == 'suspended_accounts'
    
    # Eğer izin verilen sayfalardan birine erişiyorsa devam et
    return if allowed
    
    # İzin verilmeyen sayfalarda oturumu sonlandır ve yönlendir
    username = Current.user.username
    
    # API sorgusu mu yoksa normal istek mi kontrol et
    if request.format.json? || request.path.start_with?('/api/')
      # API sorguları için JSON yanıt döndür
      terminate_session
      render json: { error: 'Your account has been suspended', status: 403 }, status: :forbidden
    else
      # Normal istekler için flash mesajı göster ve yönlendir
      # Flash mesajını önce ayarla, sonra session'ı sonlandır
      flash[:alert] = 'Your account has been suspended. You have been logged out.'
      # Flash mesajını korumak için flash.keep kullanıyoruz
      flash.keep[:alert]
      terminate_session
      redirect_to suspended_account_path(username: username)
    end
  end
  
  def require_complete_profile
    # Kullanıcı yoksa veya profili tamamsa işlem yapma
    return unless Current.user && !Current.user.profile_complete?
    
    # İzin verilen controller ve action'lar (profil düzenleme, çıkış yapma, vs.)
    allowed = (controller_name == 'profiles' && ['edit', 'update'].include?(action_name)) ||
              (controller_name == 'sessions' && action_name == 'destroy') ||
              controller_name == 'suspended_accounts'
    
    # Eğer izin verilen sayfalardan birine erişiyorsa devam et
    return if allowed
    
    # Eksik alanları belirle
    missing_fields = []
    missing_fields << "Full Name" unless Current.user.full_name.present?
    missing_fields << "Bio" unless Current.user.bio.present?
    missing_fields << "Team" unless Current.user.team.present?
    
    missing_fields_text = missing_fields.join(", ")
    
    # API sorgusu mu yoksa normal istek mi kontrol et
    if request.format.json? || request.path.start_with?('/api/')
      # API sorguları için JSON yanıt döndür
      render json: { 
        error: 'Please complete your profile first', 
        missing_fields: missing_fields,
        status: 403 
      }, status: :forbidden
    else
      # Normal istekler için profil düzenleme sayfasına yönlendir
      redirect_to profile_edit_path, alert: "Please complete your profile to continue. Missing fields: #{missing_fields_text}"
    end
  end
  
  def filter_blocked_content
    # Engellenmiş kullanıcıların içeriklerini filtrelemek için helper method
    # Bu method controller'larda override edilebilir
  end
  
  # Helper method to check if a user is blocked by current user or vice versa
  def blocked_interaction?(user)
    return false unless Current.user && user
    Current.user.blocked?(user) || Current.user.blocked_by?(user)
  end
  
  helper_method :blocked_interaction?
end
