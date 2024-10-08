class GoverningBodiesController < ApplicationController
  #before_action :set_governing_body, only: %i[ show edit update destroy ]

  # GET /governing_bodies or /governing_bodies.json
  def index
    @governing_bodies = ComplianceReport.all
  end

  # GET /governing_bodies/1 or /governing_bodies/1.json
  def show
  end

  # GET /governing_bodies/new
  def new
    @compliance_report = ComplianceReport.new
  end

  # GET /governing_bodies/1/edit
  def edit
  end

  # POST /governing_bodies or /governing_bodies.json
  def create
    @compliance_report = ComplianceReportService.new(compliance_report_params)

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

  # PATCH/PUT /governing_bodies/1 or /governing_bodies/1.json
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

  # DELETE /governing_bodies/1 or /governing_bodies/1.json
  def destroy
    @compliance_report.destroy!

    respond_to do |format|
      format.html { redirect_to governing_bodies_url, notice: "Compliance report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_governing_body
      @compliance_report = ComplianceReport.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def governing_body_params
      params.fetch(:compliance_report, {})
    end
end
