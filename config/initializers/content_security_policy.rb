# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "https://*.tiktokcdn.com", "https://i.ytimg.com"
    policy.object_src  :none
    # :unsafe_eval is required for the TikTok embed script to work.
    policy.script_src  :self, :https, "https://*.tiktok.com", "https://www.youtube.com", :unsafe_eval, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   :self, "https://www.youtube.com", "https://www.tiktok.com", "https://*.tiktok.com"
    policy.connect_src :self, :https, "https://*.tiktok.com"

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Permissions Policy to allow accelerometer, gyroscope and other sensors for TikTok embeds
  config.permissions_policy do |policy|
    policy.accelerometer "*"
    policy.gyroscope "*"
    policy.magnetometer "*"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
