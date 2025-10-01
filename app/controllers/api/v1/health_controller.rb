module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :authenticate_api_key

      def show
        render json: {
          status: "ok",
          timestamp: Time.current,
          openai: ENV["OPENAI_API_KEY"].present?
        }
      end
    end
  end
end