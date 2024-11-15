class GooglePlacesClient
  include HTTParty
  base_uri ENV['GOOGLE_PLACES_API_BASE_URL']
  
  def self.nearby_search(options={})
    opts = options.with_indifferent_access
    opts[:radius] ||= 1500
    
    params = {
      key: ENV['GOOGLE_PLACES_API_KEY'],
      location: opts[:location],
      radius: opts[:radius],
      type: opts[:type]
    }

    get("/nearbysearch/json", query: params, timeout: 10).with_indifferent_access
  end
end
