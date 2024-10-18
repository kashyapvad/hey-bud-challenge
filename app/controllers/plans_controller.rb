class PlansController < ApplicationController
  before_action :require_login
  before_action :set_plan, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!

  # GET /governing_bodies or /governing_bodies.json
  def index
    @plans = Plan.all
  end

  # GET /governing_bodies/1 or /governing_bodies/1.json
  def show
  end

  # GET /governing_bodies/new
  def new
    @plan = Plan.new
  end

  # GET /governing_bodies/1/edit
  def edit
  end

  # POST /governing_bodies or /governing_bodies.json
  def create
    file = plan_params[:pdf]
    email = plan_params[:email]
    f = GptClient.upload_file file.tempfile.path
    g = GoverningBody.first #hardcoding Kerala Government as GoverningBOdy for now
    @plan = g.plans.new email: email, file: f[:id], title: file.original_filename
    if @plan.save
      redirect_to plan_url(@plan)
    else
      redirect_to "/error"
    end
  end

  # PATCH/PUT /governing_bodies/1 or /governing_bodies/1.json
  def update
    # respond_to do |format|
    #   if @compliance_report.update(compliance_report_params)
    #     # Update PDF (if attached) with the compliance report
    #     @compliance_report.pdf.attach(params[:compliance_report][:pdf]) if params[:compliance_report][:pdf].present?

    #     format.html { redirect_to compliance_report_url(@compliance_report), notice: "Compliance report was successfully updated." }
    #     format.json { render :show, status: :ok, location: @compliance_report }
    #   else
    #     format.html { render :edit, status: :unprocessable_entity }
    #     format.json { render json: @compliance_report.errors, status: :unprocessable_entity }
    #   end
    # end

    puts "ni ayya"
  end

  # DELETE /governing_bodies/1 or /governing_bodies/1.json
  def destroy
    @compliance_report.destroy!

    respond_to do |format|
      format.html { redirect_to governing_bodies_url, notice: "Compliance report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def error
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.where(id: params[:id]).first
      @plan ||= Plan.new
    end

    # Only allow a list of trusted parameters through.
    def plan_params
      params.require(:plan).permit(:title, :pdf, :email)  # Added :PDF and email to permitted parameters
    end

    def authorize_user!
      unless @plan.organization == current_user.organization
        redirect_to root_path, alert: 'You are not authorized to access this resource.'
      end
    end
end
