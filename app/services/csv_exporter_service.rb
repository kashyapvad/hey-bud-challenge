
require 'csv'
class CsvExporterService

  FORMATS = {
    restaurants: {
      headers: [:name, :address, :rating, :total_ratings, :price_level, :geo_coordinates, :cuisine, :budget_per_person, :opening_hours, :contact_information, :special_features],
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
    properties = field.to_s.split(".").map &:to_sym
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

  def self.export_restaurants restaurants, sheet_name, tab_name
    headers = FORMATS[:restaurants][:headers]
    rows = []
    tabs_data = {}
    return unless restaurants.present?
    rows << headers.map(&:to_s).map(&:titleize)
    restaurants.each do |restaurant|
      data = extract_data(restaurant, headers)
      row = row_for_data(data, headers)
      rows << row
    end
    csv = rows_to_csv rows
    tabs_data[tab_name] = csv
    report_sheet_id = GoogleSheetClient.create_new_spreadsheet_for(sheet_name, tab_name).spreadsheet_id
    GoogleSheetClient.sync_tabs_for report_sheet_id, tabs_data
    report_sheet_id
  end

end