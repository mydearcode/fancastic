class SearchController < ApplicationController
  include Pagy::Backend
  
  def index
    @query = params[:q]&.strip
    @tab = params[:tab] || 'posts'
    
    if @query.present?
      case @tab
      when 'posts'
        @posts = Post.includes(:user)
                    .where("text ILIKE ?", "%#{@query}%")
                    .order(created_at: :desc)
                    .limit(20)
      when 'people'
        @users = User.where("username ILIKE ? OR full_name ILIKE ?", "%#{@query}%", "%#{@query}%")
                    .limit(20)
      when 'top'
        # Popüler gönderiler - trend show metodundan alınan popülerlik algoritması
        @posts = Post.includes(:user)
                    .where("text ILIKE ?", "%#{@query}%")
                    .joins("LEFT JOIN (SELECT post_id, COUNT(*) as likes_count FROM likes GROUP BY post_id) likes_agg ON posts.id = likes_agg.post_id")
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
      when 'latest'
        @posts = Post.includes(:user)
                    .where("text ILIKE ?", "%#{@query}%")
                    .order(created_at: :desc)
                    .limit(20)
      when 'hashtags'
        # Hashtag arama için tüm postları al
        @posts = Post.includes(:user)
                    .where("text ILIKE ?", "%#{@query}%")
                    .order(created_at: :desc)
                    .limit(100)
      end
    else
      @posts = []
      @users = []
    end
    
    respond_to do |format|
      format.html
      format.json do
        if params[:mention] == 'true' && request.xhr?
          # Mention özelliği için kullanıcı arama
          render json: { users: @users.map { |u| { username: u.username, full_name: u.full_name } } }
        elsif params[:hashtag] == 'true' && request.xhr?
          # Hashtag özelliği için hashtag arama
          hashtags = extract_hashtags_from_posts(@posts)
          render json: { hashtags: hashtags }
        else
          render json: { posts: @posts, users: @users }
        end
      end
    end
  end

  private

  def extract_hashtags_from_posts(posts)
    return [] unless posts
    
    hashtag_counts = Hash.new(0)
    
    posts.each do |post|
      next unless post.text
      
      # Hashtag'leri çıkar
      hashtags = post.text.scan(/#([\p{L}\p{N}_]+)/u).flatten
      hashtags.each { |hashtag| hashtag_counts[hashtag.downcase] += 1 }
    end
    
    # En popüler hashtag'leri döndür (maksimum 10)
    hashtag_counts.sort_by { |_, count| -count }
                  .first(10)
                  .map { |name, count| { name: name, count: count } }
  end
end
