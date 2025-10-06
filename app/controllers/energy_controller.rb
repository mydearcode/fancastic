class EnergyController < ApplicationController
  before_action :require_authentication
  
  def index
    @user = Current.user
    @can_claim = @user.can_claim_daily_energy?
    @daily_claim_amount = Setting.daily_claim_amount
    @last_claim_date = @user.last_claim_date
    
    # Get recent energy activities
    @recent_activities = @user.interaction_logs
                              .where('created_at > ?', 7.days.ago)
                              .order(created_at: :desc)
                              .limit(10)
  end

  def claim
    result = Current.user.claim_daily_energy
    
    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:message]
    end
    
    redirect_to energy_path
  end
end
