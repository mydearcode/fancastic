module YoutubeHelper
  # YouTube bağlantılarını tespit etmek için regex
  YOUTUBE_LINK_REGEX = %r{
    https?:\/\/(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})(?:[&?].*)?
  }x

  # Post içeriğindeki YouTube bağlantılarını iframe'e dönüştürür
  def embed_youtube_videos(content)
    return content if content.blank?

    # YouTube bağlantılarını iframe ile değiştir
    content.gsub(YOUTUBE_LINK_REGEX) do |match|
      video_id = extract_video_id(match)
      if video_id
        %{
          <div class="youtube-embed my-4" 
               onclick="event.stopPropagation(); event.preventDefault(); return false;" 
               data-turbo="false" 
               data-controller="youtube-player">
            <a href="javascript:void(0)" 
               onclick="event.stopPropagation(); event.preventDefault(); return false;" 
               data-turbo="false" 
               class="video-container">
              <iframe 
                width="100%" 
                height="315" 
                src="https://www.youtube.com/embed/#{video_id}" 
                title="YouTube video player"
                frameborder="0" 
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
                referrerpolicy="strict-origin-when-cross-origin"
                allowfullscreen>
              </iframe>
            </a>
          </div>
        }
      else
        match # Eğer video ID çıkarılamazsa, orijinal bağlantıyı göster
      end
    end.html_safe
  end

  # YouTube bağlantısından video ID'yi çıkarır
  def extract_video_id(url)
    match = url.match(YOUTUBE_LINK_REGEX)
    match ? match[1] : nil
  rescue => e
    Rails.logger.warn("YouTube video ID çıkarılamadı: #{url}, Hata: #{e.message}")
    nil
  end
end