class SearchController < ApplicationController
  include Pagy::Backend
  
  def index
    @query = params[:q]
    
    if @query.present?
      if params[:autocomplete] == 'true'
        # Autocomplete için sadece kullanıcıları döndür
        @users = User.search_by_name(@query).limit(5)
        
        render json: {
          users: @users.map do |user|
            {
              id: user.id,
              username: user.username,
              full_name: user.full_name
            }
          end
        }
      else
        # Normal arama için pagination ile
        # Search users by username and full_name
        users_query = User.search_by_name(@query)
        @pagy_users, @users = pagy(users_query, items: 5, page_param: :users_page)
        
        # Search posts by content
        posts_query = Post.search_by_content(@query).includes(:user)
        @pagy_posts, @posts = pagy(posts_query, items: 10, page_param: :posts_page)
        
        respond_to do |format|
          format.html
          format.turbo_stream
        end
      end
    else
      @users = []
      @posts = []
      @pagy_users = nil
      @pagy_posts = nil
      
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
  end
end
