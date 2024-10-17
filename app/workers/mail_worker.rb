class MailWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reports'

  def self.fire plan_id
    perform_async plan_id
  end

  def self.fire_in time, plan_id
    perform_in time, plan_id
  end

  def perform plan_id
    plan = Plan.where(id: plan_id).first
    return unless plan
    subject = "Compliance Report"
    body = "Your report has been generated - Please fine it here - https://docs.google.com/spreadsheets/d/#{plan.report_sheet_id}"
    ApplicationMailer.send_mail_with_body(subject, body, plan.email).deliver_now if plan.compliance_report.present? and plan.email.present?
  end
end