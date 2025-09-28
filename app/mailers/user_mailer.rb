class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = verify_email_url(token: @user.verification_token)
    
    mail(
      to: @user.email_address,
      subject: 'Fancastic - E-posta Adresinizi Onaylayın'
    )
  end
end
