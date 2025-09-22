class Admin::EnergyController < Admin::AdminController
  before_action :set_user, only: [:show, :update_user_energy]
  before_action :validate_energy_params, only: [:update_user_energy]
  before_action :validate_energy_costs_params, only: [:update_energy_costs]
  
  def index
    @users = User.includes(:team).order(:username)
    @pagy, @users = pagy(@users, items: 20)
    
    # Energy statistics
    @total_users = User.count
    @average_energy = User.average(:energy).to_f.round(2)
    @low_energy_users = User.where('energy < ?', 20).count
    @high_energy_users = User.where('energy >= ?', 80).count
  end
  
  def show
    @interaction_logs = FanPulse::InteractionLog.where(user: @user)
                                               .order(created_at: :desc)
                                               .limit(50)
  end

  def update_user_energy
    action_type = params[:action_type]
    amount = params[:amount].to_i
    
    case action_type
    when 'increase'
      new_energy = [@user.energy + amount, 100].min
      @user.update!(energy: new_energy)
      log_admin_action('admin_energy_increase', amount)
      flash[:notice] = "#{@user.username} kullanıcısının energy'si #{amount} artırıldı (#{new_energy}/100)"
      
    when 'decrease'
      new_energy = [@user.energy - amount, 0].max
      @user.update!(energy: new_energy)
      log_admin_action('admin_energy_decrease', -amount)
      flash[:notice] = "#{@user.username} kullanıcısının energy'si #{amount} azaltıldı (#{new_energy}/100)"
      
    when 'reset'
      @user.update!(energy: 0)
      log_admin_action('admin_energy_reset', -@user.energy_was)
      flash[:notice] = "#{@user.username} kullanıcısının energy'si sıfırlandı"
      
    when 'full'
      old_energy = @user.energy
      @user.update!(energy: 100)
      log_admin_action('admin_energy_full', 100 - old_energy)
      flash[:notice] = "#{@user.username} kullanıcısının energy'si fullenmiştir (100/100)"
      
    else
      flash[:alert] = "Geçersiz işlem türü"
    end
    
    redirect_to admin_energy_path(@user)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Energy güncellenirken hata oluştu: #{e.message}"
    redirect_to admin_energy_path(@user)
  end
  
  def energy_costs
    # Energy cost management page
  end

  def update_energy_costs
    energy_costs = params[:energy_costs]
    
    if energy_costs.present?
      begin
        # Update energy costs in database
        EnergyCostSetting.bulk_update_costs(energy_costs)
        
        # Clear the cached energy costs
        FanPulse::InteractionLog.instance_variable_set(:@energy_costs, nil)
        
        flash[:notice] = "Energy tüketim ayarları başarıyla güncellendi"
        Rails.logger.info "Admin #{Current.user.username} updated energy costs: #{energy_costs.inspect}"
        
      rescue => e
        flash[:alert] = "Energy ayarları güncellenirken hata oluştu: #{e.message}"
        Rails.logger.error "Failed to update energy costs: #{e.message}"
      end
    else
      flash[:alert] = "Geçersiz energy ayarları"
    end
    
    redirect_to energy_costs_admin_energy_index_path
  end

  def bulk_energy_restore
    restored_count = 0
    
    begin
      User.transaction do
        User.where('energy < ?', 100).find_each do |user|
          old_energy = user.energy
          user.update!(energy: 100)
          
          # Log the bulk restore action
          log_admin_action_for_user(user, 'admin_bulk_restore', 100 - old_energy)
          restored_count += 1
        end
      end
      
      flash[:notice] = "#{restored_count} kullanıcının energy'si başarıyla restore edildi"
      Rails.logger.info "Admin #{Current.user.username} performed bulk energy restore for #{restored_count} users"
      
    rescue => e
      flash[:alert] = "Bulk restore işlemi sırasında hata oluştu: #{e.message}"
      Rails.logger.error "Bulk energy restore failed: #{e.message}"
    end
    
    redirect_to admin_energy_index_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Kullanıcı bulunamadı"
    redirect_to admin_energy_index_path
  end

  def validate_energy_params
    action_type = params[:action_type]
    amount = params[:amount].to_i
    
    unless %w[increase decrease reset full].include?(action_type)
      flash[:alert] = "Geçersiz işlem türü"
      redirect_to admin_energy_path(@user) and return
    end
    
    if %w[increase decrease].include?(action_type) && (amount < 1 || amount > 100)
      flash[:alert] = "Energy miktarı 1-100 arasında olmalıdır"
      redirect_to admin_energy_path(@user) and return
    end
  end

  def validate_energy_costs_params
    energy_costs = params[:energy_costs]
    
    if energy_costs.present?
      energy_costs.each do |action, cost|
        cost_value = cost.to_i
        if cost_value < 0 || cost_value > 100
          flash[:alert] = "Energy maliyetleri 0-100 arasında olmalıdır"
          redirect_to energy_costs_admin_energy_index_path and return
        end
      end
    end
  end

  def log_admin_action(action_type, energy_delta)
    log_admin_action_for_user(@user, action_type, energy_delta)
  end

  def log_admin_action_for_user(user, action_type, energy_delta)
    FanPulse::InteractionLog.create!(
      user: user,
      action_type: action_type,
      energy_delta: energy_delta,
      target: Current.user, # Admin who performed the action
      created_at: Time.current
    )
  rescue => e
    Rails.logger.error "Failed to log admin action: #{e.message}"
  end
end