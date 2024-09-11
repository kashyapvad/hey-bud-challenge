class ExtractParametersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reports'

  def self.fire plan_id, messages, options={}
    perform_async plan_id, messages, options
  end

  def self.fire_in time, plan_id, messages, options={}
    perform_in time, plan_id, messages, options
  end

  def perform plan_id, messages, options={}
    plan = Plan.where(id: plan_id).first
    return unless plan
    parameters = ComplianceReportService.extract_parameters plan.governance_body.assistant, messages
    plan.update_report parameters
  end
end