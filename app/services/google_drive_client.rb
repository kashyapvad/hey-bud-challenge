class GoogleDriveClient
  require 'google/apis/drive_v3'
  require 'googleauth/stores/redis_token_store'

  def self.client user_id=ENV['GOOGLE_DRIVE_AUTHORIZER_USER_ID']
    client = Google::Apis::DriveV3::DriveService.new
    client.client_options.application_name = "drive-api".freeze
    client.client_options.send_timeout_sec = 1200
    client.client_options.open_timeout_sec = 1200
    client.client_options.read_timeout_sec = 1200
    client.authorization = authorize ENV['GOOGLE_DRIVE_AUTHORIZER_USER_ID']
    client
  end

  def self.authorize user_id=ENV['GOOGLE_DRIVE_AUTHORIZER_USER_ID']
    client_id = nil
    TempFileService.create_temp_file_for_content ENV['GOOGLE_SECRET_JSON'] do |temp|
      client_id = Google::Auth::ClientId.from_file temp.path
    end
    token_store = Google::Auth::Stores::RedisTokenStore.new redis: global_redis_client
    authorizer = Google::Auth::UserAuthorizer.new client_id, Google::Apis::DriveV3::AUTH_DRIVE, token_store
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

  def self.add_permission file_id, email, role, options={}
    opts = options.with_indifferent_access
    user_id = opts[:user_id] || ENV['GOOGLE_DRIVE_AUTHORIZER_USER_ID']
    permission = Google::Apis::DriveV3::Permission.new
    permission.type = 'user'
    permission.email_address = email
    permission.role = role
    client(user_id).create_permission file_id, permission, send_notification_email: opts[:send_notification_email]
  end
end