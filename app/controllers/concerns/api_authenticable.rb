# app/controllers/concerns/api_authenticatable.rb
module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_api_key
  end

  private

  def authenticate_with_api_key
    api_key = request.headers['X-Api-Key']
    @current_user = User.find_by(api_key: api_key)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
end
