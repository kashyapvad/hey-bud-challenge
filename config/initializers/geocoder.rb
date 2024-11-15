Geocoder.configure(
  timeout: 10,
  lookup: :google,
  use_https: true,
  api_key: ENV['GOOGLE_PLACES_API_KEY'],
)
