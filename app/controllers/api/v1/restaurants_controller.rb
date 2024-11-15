class Api::V1::RestaurantsController < Api::BaseController

  def home
    render json: {
      message: "Please Use Postman/CURL to test the API: api/v1/restaurants :)"
    }
  end

  def index
    # Validate required parameters
    if (!restaurant_params[:city].present? or !restaurant_params[:neighborhood].present?) and (!restaurant_params[:longitude].present? or !restaurant_params[:latitude].present?)
      raise Api::V1::Errors::CustomError, "Either city and neighborhood or coordinates (longitude/latitude) must be provided"
    end
    
    if !restaurant_params[:cuisine].present?
      raise Api::V1::Errors::CustomError, "Cuisine parameter is required"
    end

    key = "restaurants_#{restaurant_params[:city]}_#{restaurant_params[:neighborhood]}_#{restaurant_params[:cuisine]}}"

    # Get results from Redis Cache
    if restaurant_params[:city].present? and restaurant_params[:neighborhood].present?
      results = global_redis_client.get(key)
      results = eval results if results.present?
    end
    
    if restaurant_params[:longitude].present? and restaurant_params[:latitude].present?
      results = global_redis_client.get(key)
      results = eval results if results.present?
    end

    max_results = opts[:max_results].to_i.zero? ? 3 : opts[:max_results].to_i
    min_rating = opts[:min_rating].to_f.zero? ? 3.5 : opts[:min_rating].to_f
    restaurants = RestaurantService.fetch(restaurant_params.to_h)
    results = restaurants.filter! { |r| r[:rating].to_f >= min_rating }.first(max_results)

    if results.blank?
      raise Api::V1::Errors::NoResultsFoundError, "No results found matching the specified search criteria"
    else
      # Save results to Redis Cache
      if restaurant_params[:city].present? and restaurant_params[:neighborhood].present?
        global_redis_client.set(key, restaurants, ex: 10.minutes)
      end
      
      if restaurant_params[:longitude].present? and restaurant_params[:latitude].present?
        global_redis_client.set(key, restaurants, ex: 10.minutes)
      end
      RestaurantService.export_to_spreadsheet results, restaurant_params.to_h if restaurant_params[:email].present?
    end

    render json: { 
      results: results,
    }
  end

  private

  def restaurant_params
    params.permit(
      :city,
      :neighborhood,
      :longitude,
      :latitude,
      :cuisine,
      :max_results,
      :min_rating,
      :email
    )
  end
end
