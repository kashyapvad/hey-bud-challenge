class ComplianceReportService

  def self.generate_report plan
    return unless plan.file
    governing_body = plan.governance_body
    prompt_template = governing_body.prompt
    return unless prompt_template
    prompt = prompt_template.dup
    files.each do |key, files|
      case key.to_sym
      when :extraction_guide
        files.map{|v| prompt.gsub!("--GUIDE_FILE--", v) }
      when :compliance_rules
        files.map_with_index{|v, i| prompt.gsub!("--COMPLIANCE_#{i.to_s}--", v) }
      end
    end

    governing_body.parameters.each_slice(10) do | batch |
      parameters = batch.map_with_index {|p, i| "#{i.to_s}. #{p}"}.join("\n")
      content = prompt.gsub("--PARAMETERS--", parameters)
      messages = [
        {
          role: :user,
          content: :content,
          attachments: [{:file_id=>plan.file, :tools=>[{:type=>"file_search"}]}]
        }
      ]
      ComplianceReportWorker.fire plan.id.to_s, messages
    end
  end

  def self.extract_parameters assistant, messages
    response = GptClient.create_thread_and_run_assistant assistant, messages
    thread_id = response[:thread_id]
    ms = GptClient.messages thread_id
    last_message = (ms[:data]&.first || {})[:content]
    return unless last_message
    parameters = eval(last_message.first[:text][:value].gsub("`", "").gsub("json", ""))
  end
end