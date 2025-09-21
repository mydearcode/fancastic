class Admin::ReportsController < Admin::AdminController
  before_action :set_report, only: [:update, :destroy]
  
  def index
    @reports = Report.includes(:reporter, :reportable).order(created_at: :desc)
    @pagy, @reports = pagy(@reports, items: 20)
  end

  def update
    if params[:archive]
      @report.update(status: 'archived')
      redirect_to admin_reports_path, notice: "Report archived."
    elsif params[:suspend_user]
      case @report.reportable_type
      when "User"
        user = @report.reportable
      when "Post"
        user = @report.reportable.user
      when "Conversation"
        # Conversation report'unda genellikle conversation içindeki uygunsuz davranış nedeniyle
        # belirli bir kullanıcı suspend edilir. Bu durumda admin'in seçmesi gerekir.
        # Şimdilik conversation'daki ilk kullanıcıyı suspend ediyoruz
        user = @report.reportable.users.first
      else
        redirect_to admin_reports_path, alert: "Cannot suspend user for this report type"
        return
      end
      
      suspend_reason = @report.reason.present? ? @report.reason : :moderator_action
      
      if user.update(suspended: true, suspend_reason: suspend_reason, suspend_date: Date.today)
        # Log the suspension
        UserSuspensionLog.create(
          user: user,
          suspended_by: Current.user,
          suspended_at: Time.current,
          suspend_reason: suspend_reason
        )
        @report.update(status: 'resolved')
        redirect_to admin_reports_path, notice: "User suspended and report resolved."
      else
        redirect_to admin_reports_path, alert: "Failed to suspend user."
      end
    elsif @report.update(report_params)
      redirect_to admin_reports_path, notice: "Report was successfully updated."
    else
      redirect_to admin_reports_path, alert: "Failed to update report."
    end
  end

  def destroy
    @report.destroy
    redirect_to admin_reports_path, notice: "Report was successfully deleted."
  end

  private
    def set_report
      @report = Report.find(params[:id])
    end

    def report_params
      params.require(:report).permit(:status, :admin_notes)
    end
end