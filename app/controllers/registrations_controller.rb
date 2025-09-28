class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.energy = 100 # Default energy for new users
    
    begin
      if @user.save
        # Generate verification token and send email
        @user.generate_verification_token
        @user.save!
        
        UserMailer.email_verification(@user).deliver_now
        
        redirect_to new_email_verification_path, notice: "Hesabınız oluşturuldu! E-posta adresinize gönderilen onay linkine tıklayarak hesabınızı aktifleştirin."
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      if e.message.include?('email_address')
        @user.errors.add(:email_address, 'Bu e-posta adresi zaten kullanılıyor')
        render :new, status: :unprocessable_entity
      else
        raise e
      end
    end
  end

  private

  def registration_params
    params.require(:user).permit(:username, :email_address, :password, :password_confirmation)
  end
end