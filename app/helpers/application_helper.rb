module ApplicationHelper
  include Pagy::Frontend
  include YoutubeHelper
  
  # Post içeriğindeki hem YouTube hem de TikTok videolarını gömme
  def embed_videos(content)
    return content if content.blank?
    
    # Önce YouTube videolarını göm
    content_with_youtube = embed_youtube_videos(content)
    
    # Sonra TikTok videolarını göm
    content_with_tiktok = embed_tiktok_videos(content_with_youtube)
    
    # Hashtag ve mention linklerini ekle
    content_with_links = process_hashtags_and_mentions(content_with_tiktok)
    
    content_with_links.html_safe
  end
  
  # Hashtag ve mention'ları linklere çevir
  def process_hashtags_and_mentions(content)
    return content if content.blank?
    
    # Önce hashtag'leri işle
    content_with_hashtags = process_hashtags(content)
    
    # Sonra mention'ları işle
    process_mentions(content_with_hashtags)
  end
  
  # Hashtag'leri arama sayfasına yönlendiren linklere çevir
  def process_hashtags(content)
    return content if content.blank?
    
    # Hashtag regex - Unicode karakterleri destekler (Türkçe karakterler için)
    hashtag_regex = /#([\p{L}\p{N}_]+)/u
    
    content.gsub(hashtag_regex) do |match|
      hashtag = $1
      # X.com tarzında src parametresi ekle
      link_to match, search_path(q: match, src: "hashtag_click"), 
              class: "text-blue-400 hover:text-blue-300 hover:underline relative z-20",
              data: { turbo_frame: "_top" },
              onclick: "event.stopPropagation();"
    end
  end
  
  # Mention'ları kullanıcı profiline yönlendiren linklere çevir
  def process_mentions(content)
    return content if content.blank?
    
    # Mention regex - Unicode karakterleri destekler
    mention_regex = /@([\p{L}\p{N}_]+)/u
    
    content.gsub(mention_regex) do |match|
      username = $1
      
      # Kullanıcının mevcut olup olmadığını kontrol et
      if User.exists?(username: username)
        link_to match, user_profile_path(username),
                class: "text-blue-400 hover:text-blue-300 hover:underline relative z-20",
                data: { turbo_frame: "_top" },
                onclick: "event.stopPropagation();"
      else
        # Kullanıcı mevcut değilse sadece metin olarak bırak
        match
      end
    end
  end
end
