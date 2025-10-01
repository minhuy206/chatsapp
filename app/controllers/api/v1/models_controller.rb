module Api
  module V1
    class ModelsController < ApplicationController
      # GET /api/v1/models
      # Returns list of available LLM models
      def index
        models = Llm::Factory.available_models

        render json: {
          models: models.map { |model|
            {
              name: model.name,
              provider: model.provider,
              config: model.config
            }
          },
          count: models.count
        }
      end

      # GET /api/v1/models/:name
      # Returns details of a specific model
      def show
        model = LlmModel.find_by_model_name(params[:name])

        if model
          render json: {
            name: model.name,
            provider: model.provider,
            enabled: model.enabled,
            config: model.config
          }
        else
          render json: {
            error: "Model not found",
            message: "Model '#{params[:name]}' is not available"
          }, status: :not_found
        end
      end
    end
  end
end
