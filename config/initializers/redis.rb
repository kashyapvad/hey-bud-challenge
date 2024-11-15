REDIS_URI = ENV['REDISCLOUD_URL'] || ENV["REDISTOGO_URL"] || ENV["REDIS_URL"] || "redis://localhost:6379/"

REDIS_DB_NUM = {
  development: 1,
  test: 2
}

def global_redis_client
  initialize_redis_client if not $redis_client_is_initialized
  $redis_client
end

$redis_client = nil
$redis_client_is_initialized = false

def initialize_redis_client  
  def select_redis_db(redis)
    db_num = if Rails.env.development? then 1 else 2 end
    redis.select db_num
    puts ":: REDIS: using db num #{db_num}\n"
  rescue
    puts ":: REDIS:WARNING failed to switch tos db num #{db_num}!!\n"
  end

  redis_uri = URI.parse REDIS_URI

  $redis_client = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password) rescue nil

  if $redis_client
    puts ":: REDIS: connected to #{redis_uri}"
    # use default db num in test env so dev data is not clobbered
    select_redis_db($redis_client) if Rails.env.test?
  else
    puts "\n!! REDIS could not connect to #{redis_uri} !!!\n" if $redis_client.nil?
  end
  $redis_client_is_initialized=true
end