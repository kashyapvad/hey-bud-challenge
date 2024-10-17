REDIS_URI = ENV['REDISCLOUD_URL'] || ENV["REDISTOGO_URL"] || ENV["REDIS_URL"] || "redis://localhost:6379/"
REDIS_SCOPE_DATETIME_REGEX = /(\d{1,2}[-\/]\d{1,2}[-\/]\d{4})|(\d{4}[-\/]\d{1,2}[-\/]\d{1,2}) ([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9] UTC/
REDIS_SCOPE_DATETIME_SECONDS_REGEX = /(\d{1,2}[-\/]\d{1,2}[-\/]\d{4})|(\d{4}[-\/]\d{1,2}[-\/]\d{1,2}) ([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9].\d{6}(?:\d{1})?(?:\d{1})?(?:\d{1})? UTC/

REDIS_DB_NUM = {
  development: 1,
  test: 2
}


def global_redis_client
  initialize_redis_client if not $redis_client_is_initialized
  $redis_client
end


def redis_clear_dedup_keys worker_class_name="*"
  l = global_redis_client.keys "w.#{worker_class_name}*"
  puts "removing #{l.count} keys"
  global_redis_client.del *l
end

def scope_to_s scope
  s = scope.selector.to_s
  matches = s.gsub(REDIS_SCOPE_DATETIME_REGEX).map{ Regexp.last_match }
  matches += s.gsub(REDIS_SCOPE_DATETIME_SECONDS_REGEX).map{ Regexp.last_match }
  matches.each { |match| s.gsub!(match[0], "'#{match[0]}'")} if matches.present?
  s
end

def s_to_scope class_name, string
  klass = class_name.constantize
  selector = eval string
  klass.where(selector)
end

$redis_client = nil
$redis_client_is_initialized = false

# if !ENV["IN_GENERATOR"]# ENV vars not available during sandboxed rake anyway
#   initialize_redis_client
# end


def initialize_redis_client  
  def select_redis_db(redis)
    db_num = if Rails.env.development? then 1 else 2 end
    redis.select db_num
    puts ":: REDIS: using db num #{db_num}\n"
  rescue
    puts ":: REDIS:WARNING failed to switch tos db num #{db_num}!!\n"
  end

  redis_uri = URI.parse REDIS_URI

  $redis_client = Redis.new(host: redis_uri.host, port: redis_uri.port, password: ENV['REDIS_PASSWORD']) rescue nil

  if $redis_client
    puts ":: REDIS: connected to #{redis_uri}"
    # use default db num in test env so dev data is not clobbered
    select_redis_db($redis_client) if Rails.env.test?
  else
    puts "\n!! REDIS could not connect to #{redis_uri} !!!\n" if $redis_client.nil?
  end
  $redis_client_is_initialized=true
end