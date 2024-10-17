class ComplianceReportService

  def self.generate_report plan
    return unless plan.file
    governing_body = plan.governing_body
    governing_body.parameters.each_slice(10).with_index do | batch, i |
      t = i * 60.seconds
      content = batch.each_with_index.map {|p, i| "#{i.to_s}. #{p}"}.join("\n")
      messages = [
        {
          role: :user,
          content: content,
          attachments: [{:file_id=>plan.file, :tools=>[{:type=>"file_search"}]}]
        }
      ].to_s
      ExtractParametersAndUpdateReportWorker.fire_in t, plan.id.to_s, messages
    end
  end

  def self.extract_parameters assistant, messages
    response = GptClient.create_thread_and_run_assistant assistant, messages
    thread_id = response[:thread_id]
    sleep 29
    ms = GptClient.messages thread_id
    last_message = (ms[:data]&.first || {})[:content]
    return unless last_message
    eval(last_message.first[:text][:value].gsub("`", "").gsub("json", "")).with_indifferent_access
  end
end