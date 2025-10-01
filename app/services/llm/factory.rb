module Llm
  class Factory
    class << self
      # Get LLM service for the given model
      # @param model [String] Model name (e.g., 'gpt-4-turbo', 'claude-3-opus', 'gemini-1.5-pro')
      # @return [Llm::BaseService] Service instance for the provider
      # @raise [LlmErrors::ModelNotFoundError] if model is not found or disabled
      def for(model)
        provider = LlmModel.detect_provider(model)

        case provider
        when :openai
          Llm::OpenaiService.new
        when :anthropic
          Llm::AnthropicService.new
        when :google
          Llm::GoogleService.new
        else
          raise LlmErrors::ModelNotFoundError.new(
            "Unknown provider for model: #{model}",
            provider: nil,
            original_error: nil
          )
        end
      end

      # Get all available (enabled) models
      # @return [Array<LlmModel>] List of enabled models
      def available_models
        LlmModel.enabled.order(provider: :asc, name: :asc)
      end

      # Check if a model is available
      # @param model [String] Model name
      # @return [Boolean]
      def model_available?(model)
        LlmModel.find_by_model_name(model).present?
      end
    end
  end
end
