class GoogleSheetClient
  require 'googleauth/stores/redis_token_store'

  def self.client user_id=ENV['GOOGLE_AUTHORIZER_USER_ID']
    client = Google::Apis::SheetsV4::SheetsService.new
    client.client_options.application_name = "report-streaming-qa".freeze
    client.client_options.send_timeout_sec = 2400
    client.client_options.open_timeout_sec = 2400
    client.client_options.read_timeout_sec = 2400
    client.authorization = authorize user_id
    client
  end

  def self.authorize user_id=ENV['GOOGLE_AUTHORIZER_USER_ID']
    client_id = nil
    DevUtils.create_temp_file_for_content ENV['GOOGLE_SECRET_JSON'] do |temp|
      client_id = Google::Auth::ClientId.from_file temp.path
    end
    token_store = Google::Auth::Stores::RedisTokenStore.new redis: global_redis_client
    authorizer = Google::Auth::UserAuthorizer.new client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS, token_store
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: ENV['GOOGLE_OOB_URI']
      puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: ENV['GOOGLE_OOB_URI']
      )
    elsif credentials.expired?
      credentials.refresh!
    end
    credentials
  end

  def self.create_new_spreadsheet_for type, init_tab, user_id=ENV['GOOGLE_AUTHORIZER_USER_ID']
    title = "#{type.to_s.titleize} - #{init_tab.to_s}"
    spreadsheet_config = {
        properties: {
            title: title
        },
        sheets: [
            properties: {
                title: init_tab
            }
        ]
    }
    spreadsheet_id = client(user_id).create_spreadsheet(spreadsheet_config, fields: 'spreadsheetId').spreadsheet_id
    get_spreadsheet spreadsheet_id, user_id if spreadsheet_id
  end

  def self.get_spreadsheet spreadsheet_id, user_id=ENV['GOOGLE_AUTHORIZER_USER_ID']
    client(user_id).get_spreadsheet spreadsheet_id
  end

  def self.sync_tabs_for spreadsheet_id, tabs_data={}, user_id=ENV['GOOGLE_AUTHORIZER_USER_ID'], tab_index=nil
    spreadsheet = get_spreadsheet spreadsheet_id, user_id
    requests = []
    tabs = tabs_for spreadsheet
    tabs_data.symbolize_keys.each do |tab_name, csv|
      new_tab_id = rand(1_000_000_000..2_147_483_647)
      new_tab_id = rand(1_000_000_000..2_147_483_647) while tab_id_exists? spreadsheet, new_tab_id
      if tab_name_exists? spreadsheet, tab_name
        old_tab_id = tabs[tab_name]
        if tabs.count == 1
          requests += build_requests_to_add_when_only_one_sheet old_tab_id, new_tab_id, tab_name, tab_index
        else
          requests << build_request_to_delete_sheet(old_tab_id)
          requests << build_request_to_add_sheet(new_tab_id, tab_name, tab_index)
        end
      else
        requests << build_request_to_add_sheet(new_tab_id, tab_name, tab_index)
      end
      requests << build_request_to_update_sheet(new_tab_id, csv)
    end
    client(user_id).batch_update_spreadsheet(spreadsheet_id, { requests: requests }) if requests.present?
  end

  def self.extract_csv_from_sheet sheet_id, user_id=ENV['GOOGLE_AUTHORIZER_USER_ID']
    csv_string = ''
    sheet_id = extract_sheet_id_url sheet_id
    spreadsheet = get_spreadsheet sheet_id, user_id
    sheet_name = spreadsheet.sheets.first.properties.title
    rows = client(user_id).get_spreadsheet_values(sheet_id, sheet_name).values
    CSV.generate { | csv | rows.each { | row | csv << row } } if rows
  end

  def self.extract_csv_from_all_tabs_in_sheet sheet_id, tab_names=[]
    csv_data = {}
    sheet_id = extract_sheet_id_url sheet_id
    spreadsheet = get_spreadsheet sheet_id
    sheet_names = [*tab_names].flatten.compact
    sheet_names = spreadsheet.sheets.map { |s| s.properties.title } if sheet_names.empty?
    sheet_names.each do |sheet_name|
      rows = client.get_spreadsheet_values(sheet_id, sheet_name).values
      csv_data[sheet_name] = CSV.generate { | csv | rows.each { | row | csv << row } } if rows
    end
    csv_data
  end

  def self.extract_sheet_id_url sheet_url_or_id
    sheet_id = sheet_url_or_id.match(/\/d\/([a-zA-Z0-9-_]+)/)[1] if sheet_url_or_id.include? "/"
    sheet_id ||= sheet_url_or_id
    sheet_id
  end

  def self.tabs_for spreadsheet
    tabs = {}
    spreadsheet.sheets.each { |sheet| tabs[sheet.properties.title.to_sym] = sheet.properties.sheet_id}
    tabs
  end

  def self.tab_name_exists? spreadsheet, tab_name
    tabs_for(spreadsheet).symbolize_keys.keys.include? tab_name.to_sym
  end

  def self.tab_id_exists? spreadsheet, tab_id
    tabs_for(spreadsheet).values.include? tab_id
  end

  def self.build_request_to_add_sheet sheet_id, sheet_name, index=nil
    return { add_sheet: { properties: { sheet_id: sheet_id, title: sheet_name, index: index } } } if index
    { add_sheet: { properties: { sheet_id: sheet_id, title: sheet_name } } }
  end

  def self.build_request_to_update_sheet sheet_id, data
    { paste_data: { coordinate: { sheet_id: sheet_id, row_index: 0, column_index: 0 }, data: data, delimiter: ','}}
  end

  def self.build_request_to_delete_sheet sheet_id
    { delete_sheet: { sheet_id: sheet_id } }
  end

  def self.build_requests_to_add_when_only_one_sheet old_tab_id, new_tab_id, tab_name, tab_index=nil
    [build_request_to_add_sheet('123456', 'placeholder'),
     build_request_to_delete_sheet(old_tab_id),
     build_request_to_add_sheet(new_tab_id, tab_name, tab_index),
     build_request_to_delete_sheet('123456')]
  end
end