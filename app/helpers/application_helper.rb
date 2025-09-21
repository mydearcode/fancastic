module ApplicationHelper
  include Pagy::Frontend
  include YoutubeHelper
  
  # Post içeriğindeki hem YouTube hem de TikTok videolarını gömme
  def embed_videos(content)
    return content if content.blank?
    
    # Önce YouTube videolarını göm
    content_with_youtube = embed_youtube_videos(content)
    
    # Sonra TikTok videolarını göm
    embed_tiktok_videos(content_with_youtube).html_safe
  end
end
