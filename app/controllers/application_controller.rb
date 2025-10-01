class ApplicationController < ActionController::API
  include Concerns::ErrorHandling

  before_action :authenticate_api_key

  private

  def authenticate_api_key
    api_key = request.headers['Authorization']&.remove('Bearer ')
    valid_keys = ENV.fetch('API_KEYS', '').split(',').map(&:strip)

    unless valid_keys.include?(api_key)
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def current_user_identifier
    request.headers['Authorization']&.remove('Bearer ')&.first(10) || 'anonymous'
  end
end
