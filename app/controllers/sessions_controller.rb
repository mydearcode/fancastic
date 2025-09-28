class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      # Check if email is verified
      unless user.email_verified?
        redirect_to new_email_verification_path, alert: "Giriş yapmadan önce e-posta adresinizi onaylamanız gerekiyor. Onay e-postasını tekrar göndermek için e-posta adresinizi girin."
        return
      end
      
      start_new_session_for user
      
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.turbo_stream { redirect_to after_authentication_url }
      end
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
