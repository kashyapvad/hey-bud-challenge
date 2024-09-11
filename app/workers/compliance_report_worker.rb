class ComplianceReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'reports'

  def self.fire assistant, messages, options={}
    perform_async options
  end

  def self.fire_in time, assistant, messages, options={}
    perform_in time, options
  end

  def perform assistant, messages, options={}
    return unless assistant
    response = GptClient.create_thread_and_run_assistant assistant, messages
    thread_id = response[:thread_id]
    ms = GptClient.messages thread_id
    last_message = (ms[:data]&.first || {})[:content]
    return unless last_message
    parameters = eval(last_message.first[:text][:value].gsub("`", "").gsub("json", ""))
    ComplianceReportService.update_report plan, parameters
  end
end