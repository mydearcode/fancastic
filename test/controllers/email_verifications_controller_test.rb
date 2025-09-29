require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @user.update!(
      email_verified: false,
      verification_token: SecureRandom.urlsafe_base64(32),
      verification_sent_at: Time.current
    )
  end

  test "should get new" do
    get new_email_verification_url
    assert_response :success
  end

  test "should verify email with valid token" do
    get verify_email_url(@user.verification_token)
    assert_redirected_to profile_edit_path
    assert_equal "E-posta adresiniz başarıyla onaylandı! Şimdi profilinizi tamamlayın.", flash[:notice]
    @user.reload
    assert @user.email_verified?
  end

  test "should reject invalid token" do
    get verify_email_url("invalid_token")
    assert_redirected_to root_path
    assert_equal "Geçersiz onay linki.", flash[:alert]
  end

  test "should reject expired token" do
    @user.update!(verification_sent_at: 25.hours.ago)
    get verify_email_url(@user.verification_token)
    assert_redirected_to new_email_verification_path
    assert_equal "Onay linki süresi dolmuş. Yeni bir onay e-postası gönderin.", flash[:alert]
  end

  test "should handle already verified email" do
    @user.update!(email_verified: true)
    get verify_email_url(@user.verification_token)
    assert_redirected_to root_path
    assert_equal "E-posta adresiniz zaten onaylanmış.", flash[:notice]
  end

  test "should create new verification email" do
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post email_verifications_url, params: { email: @user.email_address }
    end
    assert_redirected_to new_email_verification_path
    assert_equal "Onay e-postası gönderildi. E-posta kutunuzu kontrol edin.", flash[:notice]
  end

  test "should reject non-existent email" do
    post email_verifications_url, params: { email: "nonexistent@example.com" }
    assert_redirected_to new_email_verification_path
    assert_equal "Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.", flash[:alert]
  end

  test "should reject already verified email for create" do
    @user.update!(email_verified: true)
    post email_verifications_url, params: { email: @user.email_address }
    assert_redirected_to root_path
    assert_equal "E-posta adresiniz zaten onaylanmış.", flash[:notice]
  end

  # Rate limiting tests for show action
  test "should rate limit show action after 5 attempts" do
    # Make 5 requests with invalid tokens
    5.times do |i|
      get verify_email_url("invalid_token_#{i}")
      assert_redirected_to root_path
    end

    # 6th request should be rate limited
    get verify_email_url("invalid_token_6")
    assert_redirected_to root_path
    assert_equal "Çok fazla deneme yaptınız. 15 dakika sonra tekrar deneyin.", flash[:alert]
  end

  # Rate limiting tests for create action
  test "should rate limit create action after 3 attempts" do
    # Make 3 requests
    3.times do |i|
      post email_verifications_url, params: { email: "test#{i}@example.com" }
    end

    # 4th request should be rate limited
    post email_verifications_url, params: { email: "test4@example.com" }
    assert_redirected_to new_email_verification_path
    assert_equal "Çok fazla e-posta gönderme isteği. 5 dakika sonra tekrar deneyin.", flash[:alert]
  end

  test "should prevent resending verification too quickly" do
    # First request should work
    post email_verifications_url, params: { email: @user.email_address }
    assert_redirected_to new_email_verification_path
    assert_equal "Onay e-postası gönderildi. E-posta kutunuzu kontrol edin.", flash[:notice]

    # Immediate second request should be rejected
    post email_verifications_url, params: { email: @user.email_address }
    assert_redirected_to new_email_verification_path
    assert_equal "Yeni onay e-postası göndermek için 5 dakika beklemelisiniz.", flash[:alert]
  end

  test "should allow resending after 5 minutes" do
    # First request
    post email_verifications_url, params: { email: @user.email_address }
    
    # Update sent time to 6 minutes ago
    @user.update!(verification_sent_at: 6.minutes.ago)
    
    # Second request should work
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post email_verifications_url, params: { email: @user.email_address }
    end
    assert_redirected_to new_email_verification_path
    assert_equal "Onay e-postası gönderildi. E-posta kutunuzu kontrol edin.", flash[:notice]
  end
end