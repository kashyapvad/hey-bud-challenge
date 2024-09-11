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
      ComplianceReportWorker.fire governing_body.assistant, messages
    end
  end

  def self.update_report plan, parameters
    return unless parameters
    report = plan.report || {}
    report[:parameters] ||= []
    report[:parameters] += parameters
    plan.set report: report
  end
end