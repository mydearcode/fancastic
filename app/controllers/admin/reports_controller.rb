class Admin::ReportsController < Admin::AdminController
  before_action :set_report, only: [:update, :destroy]
  
  def index
    @reports = Report.includes(:reporter, :reportable).order(created_at: :desc)
    @pagy, @reports = pagy(@reports, items: 20)
  end

  def update
    if @report.update(report_params)
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