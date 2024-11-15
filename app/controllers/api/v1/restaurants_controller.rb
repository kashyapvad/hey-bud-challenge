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

    results = RestaurantService.fetch(restaurant_params.to_h)
    if results.blank?
      raise Api::V1::Errors::NoResultsFoundError, "No results found matching the specified search criteria"
    elsif restaurant_params[:email].present?
      RestaurantService.export_to_spreadsheet results, restaurant_params.to_h
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
