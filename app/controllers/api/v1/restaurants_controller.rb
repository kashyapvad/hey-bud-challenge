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

    key = "restaurants_#{restaurant_params[:city]}_#{restaurant_params[:neighborhood]}_#{restaurant_params[:cuisine]}_#{restaurant_params[:max_results]}}"

    # Get results from Redis Cache
    if restaurant_params[:city].present? and restaurant_params[:neighborhood].present?
      results = global_redis_client.get(key)
      results = eval results if results.present?
    end
    
    if restaurant_params[:longitude].present? and restaurant_params[:latitude].present?
      results = global_redis_client.get(key)
      results = eval results if results.present?
    end

    results = RestaurantService.fetch(restaurant_params.to_h) if results.blank?

    if results.blank?
      raise Api::V1::Errors::NoResultsFoundError, "No results found matching the specified search criteria"
    else
      # Save results to Redis Cache
      if restaurant_params[:city].present? and restaurant_params[:neighborhood].present?
        global_redis_client.set(key, results, ex: 10.minutes)
      end
      
      if restaurant_params[:longitude].present? and restaurant_params[:latitude].present?
        global_redis_client.set(key, results, ex: 10.minutes)
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
