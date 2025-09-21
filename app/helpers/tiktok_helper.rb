module TiktokHelper
  # TikTok videolarını doğrudan embed kodu kullanarak göstermek için
  def embed_tiktok_videos(text)
    return text unless text.present?

    text.to_str.gsub(%r{https?://(?:www\.)?tiktok\.com/@([^/]+)/video/(\d+)(?:[^\s]*)?}i) do |match|
      username = $1
      video_id = $2
      embed_tiktok_video(username, video_id)
    end
  end
  
  # Belirli bir TikTok videosunu embed etmek için
  def embed_tiktok_video(username, video_id)
    begin
      # TikTok'un güncel embed URL formatını kullan - autoplay=0 parametresi ile otomatik oynatmayı devre dışı bırak
      embed_html = <<-HTML
        <div class="tiktok-embed-wrapper">
          <iframe 
            src="https://www.tiktok.com/embed/#{video_id}?autoplay=0" 
            width="100%" 
            height="740" 
            frameborder="0" 
            allow="accelerometer; gyroscope; magnetometer; encrypted-media; fullscreen; picture-in-picture"
            sandbox="allow-scripts allow-same-origin allow-popups allow-presentation allow-forms"
            referrerpolicy="strict-origin-when-cross-origin"
            style="max-width: 605px; min-width: 325px; border: none;"
            loading="lazy"
            title="TikTok video by @#{username}">
          </iframe>
        </div>
      HTML
      
      # HTML içeriğini güvenli olarak döndür
      embed_html.html_safe
    rescue => e
      # Hata durumunda logla ve fallback göster
      Rails.logger.error "TikTok embed error: #{e.message}"
      "<div class='video-unavailable'>TikTok videosu yüklenemedi. Lütfen daha sonra tekrar deneyin.</div>".html_safe
    end
  end
end