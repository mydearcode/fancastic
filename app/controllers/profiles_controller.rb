class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_teams, only: [:edit, :update]
  before_action :set_tab, only: [:show, :show_user]
  
  def show
    @user = Current.user
    @is_own_profile = true
    load_user_content
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show_user
    # Username ile kullanıcı bul
    @user = User.find_by!(username: params[:username])
    @is_own_profile = @user == Current.user
    
    # Kullanıcı suspend edilmiş mi kontrol et
    if @user.suspended?
      redirect_to suspended_account_path(@user.username) and return
    end
    
    # Engelleme durumlarını kontrol et
    @blocked_by_user = Current.user.blocked_by?(@user)
    @user_blocked = Current.user.blocked?(@user)
    
    # Engelleme durumunda bile profil sayfasını göster, sadece içeriği değiştir
    if @blocked_by_user || @user_blocked
      # Engelleme durumunda boş posts array'i ata
      @posts = []
      @pagy = nil
    else
      load_user_content
    end
    
    respond_to do |format|
      format.html { render :show }
      format.turbo_stream { render "show" }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Kullanıcı bulunamadı"
  end
  
  def redirect_legacy_profile
    # Eski /users/:id URL'lerini yeni formata yönlendir
    user = User.find(params[:id])
    redirect_to user_profile_path(user.username), status: :moved_permanently
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Kullanıcı bulunamadı"
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    
    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to profile_path, notice: "Profile updated successfully." }
        format.turbo_stream { redirect_to profile_path, notice: "Profile updated successfully." }
      end
    else
      set_teams
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def set_tab
    @tab = params[:tab] || 'posts'
  end
  
  def load_user_content
    case @tab
    when 'posts'
      posts_query = @user.posts.where(in_reply_to_post_id: nil)
                         .includes(:user, :repost_of_post, :quote_of_post)
                         .order(created_at: :desc)
    when 'replies'
      posts_query = @user.posts.where.not(in_reply_to_post_id: nil)
                         .includes(:user, :in_reply_to_post)
                         .order(created_at: :desc)
    when 'likes'
      posts_query = Post.joins(:likes)
                        .where(likes: { user_id: @user.id })
                        .includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                        .order('likes.created_at DESC')
    else
      posts_query = @user.posts.includes(:user, :in_reply_to_post, :repost_of_post, :quote_of_post)
                         .order(created_at: :desc)
    end
    
    @pagy, @posts = pagy(posts_query, items: 5) if posts_query
  end
  
  def user_params
    params.require(:user).permit(:full_name, :username, :team_id, :message_privacy, :profile_picture, :cover_picture, :bio, :location, :website, :birth_date, rival_team_ids: [])
  end
  
  def set_teams
    @teams = Team.includes(:league, :country).order("countries.name, leagues.name, teams.name")
  end
  
  def can_message_user?(user)
    case user.message_privacy
    when 'everyone'
      true
    when 'followers'
      # Check if target user is following the current user (karşılıklı takip)
      user.following?(Current.user)
    when 'team_mates'
      # Check if both users are on the same team or if target user is following current user
      (Current.user.team_id.present? && Current.user.team_id == user.team_id) || user.following?(Current.user)
    when 'nobody'
      false
    else
      false
    end
  end
  
  helper_method :can_message_user?
end
