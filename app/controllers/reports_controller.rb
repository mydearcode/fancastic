class ReportsController < ApplicationController
  before_action :require_authentication
  before_action :set_report, only: [:update, :destroy]
  before_action :require_admin, only: [:index, :update, :destroy]
  
  def index
    @reports = Report.includes(:reporter, :reportable).order(created_at: :desc)
    @pagy, @reports = pagy(@reports, items: 20)
  end
  
  def new
    @report = Report.new
    @reportable_type = params[:reportable_type]
    @reportable_id = params[:reportable_id]
    
    # Find the reportable object
    @reportable = @reportable_type.constantize.find(@reportable_id) if @reportable_type.present? && @reportable_id.present?
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = Current.user
    
    if @report.save
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Report submitted successfully." }
        format.json { render json: { success: true, message: "Report submitted successfully." } }
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash", locals: { notice: "Report submitted successfully." }),
            turbo_stream.update("modal", "")
          ]
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @report.errors.full_messages } }
      end
    end
  end
  
  def update
    if params[:archive]
      @report.archived!
      redirect_to reports_path, notice: "Report archived."
    elsif params[:suspend_user]
      user = @report.reportable_type == "User" ? @report.reportable : @report.reportable.user
      suspend_reason = @report.reason.present? ? @report.reason : :moderator_action
      
      if user.update(suspended: true, suspend_reason: suspend_reason, suspend_date: Date.today)
        # Log the suspension
        UserSuspensionLog.create(
          user: user,
          suspended_by: Current.user,
          suspended_at: Time.current,
          suspend_reason: suspend_reason
        )
        @report.resolved!
        redirect_to reports_path, notice: "User suspended and report resolved."
      else
        redirect_to reports_path, alert: "Failed to suspend user."
      end
    end
  end
  
  def destroy
    @report.destroy
    redirect_to reports_path, notice: "Report deleted."
  end
  
  private
  
  def set_report
    @report = Report.find(params[:id])
  end
  
  def report_params
    params.require(:report).permit(:reason, :reportable_type, :reportable_id)
  end
  
  def require_admin
    redirect_to root_path, alert: "Unauthorized access." unless Current.user.admin?
  end
end
