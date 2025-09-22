class TrendsController < ApplicationController
  allow_unauthenticated_access
  
  def index
    # Mevcut zamanı al
    simdiki_zaman = Time.current
    
    # Son 3 saatlik penceredeki trendleri getir (daha geniş aralık)
    # Duplicate phrase'leri engellemek için group by kullan ve en yüksek count'u al
    @trending_topics = TrendEntry
                      .select("phrase, MAX(count) as count, MAX(window_start) as window_start, MAX(window_end) as window_end")
                      .where(window: "1h")
                      .where("window_start >= ?", 3.hours.ago)
                      .group(:phrase)
                      .order("MAX(count) DESC")
                      .limit(10)
                      .to_a

    # Hata ayıklama için loglar
    Rails.logger.info "=== TREND ANALİZİ ==="
    Rails.logger.info "Şu anki zaman: #{simdiki_zaman}"
    Rails.logger.info "Aranan aralık: #{15.minutes.ago} - #{Time.current}"
    Rails.logger.info "Bulunan trend sayısı: #{@trending_topics.size}"
    
    # Trendler varsa ilk 5'inin detaylarını logla
    if @trending_topics.any?
      Rails.logger.info "İlk 5 trend:"
      @trending_topics.first(5).each_with_index do |t, i|
        Rails.logger.info "##{i+1}: #{t.phrase} (adet: #{t.count}, başlangıç: #{t.window_start})"
      end
    else
      Rails.logger.info "Bu aralıkta trend bulunamadı."
      # Son 3 kaydı göster
      son_kayitlar = TrendEntry.order(window_start: :desc).limit(3)
      if son_kayitlar.any?
        Rails.logger.info "Son 3 kayıt:"
        son_kayitlar.each do |kayit|
          Rails.logger.info "- #{kayit.phrase} (adet: #{kayit.count}, başlangıç: #{kayit.window_start}, bitiş: #{kayit.window_end})"
        end
      end
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("trending_list", partial: "list", locals: { trending_topics: @trending_topics })
      end
    end
  rescue => hata
    Rails.logger.error "Trend yüklenirken hata: #{hata.message}\n#{hata.backtrace.join("\n")}"
    @trending_topics = []
    
    respond_to do |format|
      format.html { render :index, status: :ok }
      format.turbo_stream do 
        render turbo_stream: turbo_stream.update("trending_list", 
          "<div class='p-4 text-red-500'>Trendler yüklenirken bir hata oluştu: #{hata.message}</div>"
        )
      end
    end
  end
  
  def show
    @phrase = params[:phrase] || params[:id]
    @tab = params[:tab] || 'top'
    @page = params[:page]&.to_i || 1
    
    # Hashtags tablosu olmadığı için post text'inden arama yapıyoruz
    search_pattern = if @phrase.start_with?('#')
      @phrase.downcase
    elsif @phrase.start_with?('@')
      @phrase.downcase
    else
      # Normal kelime araması için hem hashtag hem de normal kelime olarak ara
      [@phrase.downcase, "##{@phrase.downcase}"]
    end
    
    posts_query = Post.includes(:user)
                     .where.not(text: [nil, ''])
    
    if search_pattern.is_a?(Array)
      # Normal kelime - hem hashtag hem de text içinde ara
      posts_query = posts_query.where(
        "LOWER(text) LIKE ? OR LOWER(text) LIKE ?", 
        "%#{search_pattern[0]}%", 
        "%#{search_pattern[1]}%"
      )
    else
      # Hashtag veya mention araması
      posts_query = posts_query.where("LOWER(text) LIKE ?", "%#{search_pattern}%")
    end
    
    if @tab == 'latest'
      @posts = posts_query.order(created_at: :desc)
                         .limit(20)
                         .offset((@page - 1) * 20)
    else # top tab - popülerlik skoruna göre sırala
      @posts = posts_query.joins("LEFT JOIN (SELECT post_id, COUNT(*) as likes_count FROM likes GROUP BY post_id) likes_agg ON posts.id = likes_agg.post_id")
                         .joins("LEFT JOIN (SELECT repost_of_post_id, COUNT(*) as reposts_count FROM posts WHERE repost_of_post_id IS NOT NULL GROUP BY repost_of_post_id) reposts_agg ON posts.id = reposts_agg.repost_of_post_id")
                         .joins("LEFT JOIN (SELECT quote_of_post_id, COUNT(*) as quotes_count FROM posts WHERE quote_of_post_id IS NOT NULL GROUP BY quote_of_post_id) quotes_agg ON posts.id = quotes_agg.quote_of_post_id")
                         .select("posts.*, 
                                 COALESCE(likes_agg.likes_count, 0) as likes_count_calc,
                                 COALESCE(reposts_agg.reposts_count, 0) as reposts_count_calc,
                                 COALESCE(quotes_agg.quotes_count, 0) as quotes_count_calc,
                                 (COALESCE(likes_agg.likes_count, 0) * 1.0 + 
                                  COALESCE(reposts_agg.reposts_count, 0) * 2.0 + 
                                  COALESCE(quotes_agg.quotes_count, 0) * 1.5) as popularity_score")
                         .order("popularity_score DESC, posts.created_at DESC")
                         .limit(20)
                         .offset((@page - 1) * 20)
    end
    
    Rails.logger.info "=== TREND SHOW ANALİZİ ==="
    Rails.logger.info "Aranan phrase: #{@phrase}"
    Rails.logger.info "Search pattern: #{search_pattern}"
    Rails.logger.info "Bulunan post sayısı: #{@posts.size}"
    
    respond_to do |format|
      format.html
      format.turbo_stream do
        if @page > 1
          render turbo_stream: turbo_stream.append("posts_list", 
            render_to_string(partial: "posts_page", 
                           locals: { posts: @posts, phrase: @phrase, tab: @tab, page: @page })
          )
        else
          render "show"
        end
      end
    end
  rescue => e
    Rails.logger.error "Trend show error: #{e.message}\n#{e.backtrace.join("\n")}"
    @posts = []
    
    respond_to do |format|
      format.html { redirect_to trends_path, alert: "Trend gönderileri yüklenirken bir hata oluştu." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("posts_list",
          "<div class='p-4 text-red-500'>Gönderiler yüklenirken bir hata oluştu: #{e.message}</div>"
        )
      end
    end
  end
end
