class RestaurantService

  PROMPT = "I have a list of restaurants fetched from the Google Places API. I would like you to enrich this data, but only if certain key attributes are missing and accurate information can be added. Specifically:\nCuisine(s) (e.g., Italian, Indian, Japanese, etc.) – \nPrice Level for (e.g., $ for budget-friendly, $$ for moderate, $$$ for expensive) – Add only if it is missing.\nBudget per person (e.g., $40 per person)\nAdditional Context, if available, such as:\nOpening Hours (e.g., open now, closing time) - Enrich only if this information is not already present.\nRatings and total Ratings - Enrich only if this information is not already present.\nAddress - Enrich only if this information is not already present.\nContact Information (e.g., phone number)\nSpecial Features (e.g., outdoor seating, vegan options, etc.)\nImportant: Only provide data that is verifiable or exists. If you cannot find specific information, do not generate or guess the data. Instead, leave the field unchanged or mark it as 'N/A' if appropriate.\nPlease return the updated data in JSON format, maintaining a clear and consistent structure.\nHandling Different Cuisine Combinations\nTo cover various cuisine types and subcategories:\nItalian: Pizza, Pasta, Risotto, etc. (e.g., \"Italian - Pizza\")\nAmerican: Burgers, Sandwich, BBQ, etc. (e.g., \"American - Burger\")\nMexican: Tacos, Burritos, Quesadillas, etc. (e.g., \"Mexican - Tacos\")\nChinese: Dim Sum, Szechuan, Noodles, etc. (e.g., \"Chinese - Dim Sum\")\nJapanese: Sushi, Ramen, Tempura, etc. (e.g., \"Japanese - Sushi\")\nExample Combinations:\nIf the restaurant serves pizza, the model should output \"Italian - Pizza\".\nIf the restaurant is known for sandwiches, it should return \"American - Sandwich\".\nIf there is no obvious subcategory, the model should default to the main cuisine, like \"Japanese\" or \"Mexican\".\nHere are the list of restaurants in JSON format: {{RESTAURANTS_LIST}} \nMake sure that no data is fabricated. If an attribute cannot be accurately filled, leave it as is or mark it as 'N/A' **make sure your response is only in JSON format and no additional text or characters like `**"

  def self.search options={}
    opts = options.with_indifferent_access
    query = {}
    query[:type] = 'restaurant'
    latitude = opts[:latitude]
    longitude = opts[:longitude]
    city = opts[:city]
    neighborhood = opts[:neighborhood]

    if latitude.present? and longitude.present?
      query[:location] = "#{latitude}, #{longitude}"
    else
      coordinates = Geocoder.coordinates("#{neighborhood}, #{city}")
      query[:location] = "#{coordinates.first}, #{coordinates.last}"
    end

    resposne = GooglePlacesClient.nearby_search(query).with_indifferent_access
    raise "Service Unavailable", resposne[:status] if resposne[:status] != "OK"
    results = (resposne[:results] || [])
    restaurants = results.map do |result|
      r = Restaurant.new()
      r.name = result[:name]
      r.address = result[:vicinity]
      r.rating = result[:rating]
      r.total_ratings = result[:user_ratings_total]
      r.set_price_level result[:price_level]
      lat = result.dig(:geometry, :location, :lat)
      lng = result.dig(:geometry, :location, :lng)
      r.geo_coordinates = [lat, lng].compact
      r.geo_locate unless r.geo_coordinates.present?
      r
    end
    restaurants
    # We can use other API's like serpAPI to get more places and thendeduplicate, etc.
  end

  def self.enrich restaurants, options={}
    opts = options.with_indifferent_access
    llm = opts[:llm] || "OpenAi"
    prompt = RestaurantService::PROMPT.gsub("{{RESTAURANTS_LIST}}", restaurants.map { |r| r.attributes.except("_id") }.to_json)
    response = "#{llm}Client".constantize.send_prompt(prompt)
    raise "Service Unavailable", response[:error] if response[:error].present?
    eval(response[:choices].first[:message][:content].gsub("json", "").gsub("`", "")) || []
    # We can parse this data and then save it to database
  end

  def self.fetch options={}
    opts = options.with_indifferent_access
    key = nil
    if opts[:city].present? and opts[:neighborhood].present?
      key = "restaurants_#{opts[:city]}_#{opts[:neighborhood]}}}"
    end

    if opts[:longitude].present? and opts[:latitude].present?
      key = "restaurants_#{opts[:longitude]}_#{opts[:latitude]}}}"
    end

    cuisine = opts[:cuisine].to_s.downcase.squish
    max_results = opts[:max_results].to_i.zero? ? 3 : opts[:max_results].to_i
    min_rating = opts[:min_rating].to_f.zero? ? 3.5 : opts[:min_rating].to_f

    # Get results from Redis Cache
    restaurants = global_redis_client.get(key)
    restaurants = eval restaurants if restaurants.present?
    if restaurants.blank?
      restaurants = RestaurantService.search(opts)
      restaurants = RestaurantService.enrich(restaurants, opts)
    end
    sorted_restaurants = restaurants.sort_by { |r| -r[:rating].to_f }

    # Save results to Redis Cache
    global_redis_client.set(key, sorted_restaurants, ex: 10.minutes)
    
    data = sorted_restaurants.filter do |r| 
      restaurant_cuisine = r[:cuisine].to_s.downcase.squish
      search_cuisine = cuisine.to_s.downcase.squish
      restaurant_cuisine.include?(search_cuisine) || search_cuisine.include?(restaurant_cuisine)
    end
    data = data.select { |r| r[:rating].to_f >= min_rating }
    data.first(max_results)
  end

  def self.export_to_spreadsheet restaurants, options={}
    opts = options.with_indifferent_access
    email = opts[:email].squish.downcase
    return unless email.present?
    tab_name = opts[:cuisine] || "Restaurants"
    sheet_id = CsvExporterService.export_restaurants restaurants, :restaurants, tab_name
    GoogleDriveClient.add_permission sheet_id, email, 'reader'
  end
end
