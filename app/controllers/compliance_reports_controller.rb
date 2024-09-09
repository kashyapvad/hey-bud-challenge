class ComplianceReportsController < ApplicationController
  before_action :set_compliance_report, only: %i[ show edit update destroy ]

  # GET /compliance_reports or /compliance_reports.json
  def index
    @compliance_reports = ComplianceReport.all
  end

  # GET /compliance_reports/1 or /compliance_reports/1.json
  def show
  end

  # GET /compliance_reports/new
  def new
    @compliance_report = ComplianceReport.new
  end

  # GET /compliance_reports/1/edit
  def edit
  end

  # POST /compliance_reports or /compliance_reports.json
  def create
    @compliance_report = ComplianceReport.new(compliance_report_params)

    respond_to do |format|
      if @compliance_report.save
        format.html { redirect_to compliance_report_url(@compliance_report), notice: "Compliance report was successfully created." }
        format.json { render :show, status: :created, location: @compliance_report }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @compliance_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /compliance_reports/1 or /compliance_reports/1.json
  def update
    respond_to do |format|
      if @compliance_report.update(compliance_report_params)
        format.html { redirect_to compliance_report_url(@compliance_report), notice: "Compliance report was successfully updated." }
        format.json { render :show, status: :ok, location: @compliance_report }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @compliance_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /compliance_reports/1 or /compliance_reports/1.json
  def destroy
    @compliance_report.destroy!

    respond_to do |format|
      format.html { redirect_to compliance_reports_url, notice: "Compliance report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_compliance_report
      @compliance_report = ComplianceReport.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def compliance_report_params
      params.fetch(:compliance_report, {})
    end
end
