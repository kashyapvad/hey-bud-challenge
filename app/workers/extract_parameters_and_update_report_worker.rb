class ExtractParametersAndUpdateReportWorker
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
    governing_body = plan.governing_body
    return unless governing_body
    assistant = governing_body.assistant
    return unless assistant
    ms = eval messages
    report = ComplianceReportService.extract_parameters plan.governing_body.assistant, ms
    plan.update_report report
  end
end