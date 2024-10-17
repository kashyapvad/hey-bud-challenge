
require 'csv'
class CsvExporterService

  FORMATS = {
    compliance_report: {
      headers: ["description", "extracted/analyzed_value", "kmbr_requirement", "compliance_status"],
      field_mapping: {}
    }
  }

  def self.extract_data resource, headers, field_mapping={}, data={}
    fields = field_mapping.with_indifferent_access
    headers.each do |attr|
      next if attr.nil?
      mapping = fields[attr] || attr
      data[attr] = extract_field(resource, mapping) unless data[attr]
    end
    data
  end

  def self.extract_field instance, field
    method_collisions = [:zip] # dont call data.send(:zip) when you want data[:zip] since zip is already a built in method and not zipcode
    properties = field.split(".").map &:to_sym
    data = instance
    data = data.with_indifferent_access if data.respond_to? :with_indifferent_access
    properties.each do |property|
      if data.present? and data.respond_to?(:[])
        if data.respond_to?(property) and not method_collisions.include? property
          data = data.send property # load relationship (prolly)
        else
          data = data[property] # get property
        end
      elsif data.present? and data.respond_to?(property)
        data = data.send property
      else
        data = nil
      end
    end
    data
  end

  def self.row_for_data data, headers, options={}
    row = [] 
    remove_comma = options[:remove_comma] || false
    headers.each do |field|
      if field.nil?
        row << ""
        next
      end
      
      item = data[field]
      item ||= data.send field if data.respond_to? field
      item = item.join(" | ") if item.kind_of?(Array)
      item = item.to_s.gsub(",", "- ") if remove_comma
      row << item
    end
    row
  end
  
  def self.rows_to_csv rows, headers=nil
    CSV.generate do |csv|
      csv << headers if headers
      rows.each { |row| csv << row }
    end
  end

  def self.export_compliance_report plan
    headers = FORMATS[:compliance_report][:headers]
    rows = []
    tabs_data = {}
    report =  plan.compliance_report[:parameters]
    summary = plan.compliance_report[:summary]
    return unless report.present?
    rows << headers.map(&:to_s).map(&:titleize)
    report.each do |h|
      resource = h.transform_keys { |k| k.downcase.to_key }
      data = extract_data(resource, headers)
      row = row_for_data(data, headers)
      rows << row
    end
    rows += [[""], ["Summary"]]
    rows += summary.map{|s| [s]}
    rows
    csv = rows_to_csv rows
    tabs_data[plan.title] = csv
    report_sheet_id = plan.report_sheet_id
    report_sheet_id ||= GoogleSheetClient.create_new_spreadsheet_for(:compliance_report, plan.title).spreadsheet_id
    plan.set report_sheet_id: report_sheet_id unless plan.report_sheet_id.present?
    GoogleSheetClient.sync_tabs_for report_sheet_id, tabs_data
  end

end