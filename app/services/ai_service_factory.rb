# Factory for creating AI service instances based on model type.
#
# Supports OpenAI GPT models (gpt-4, gpt-4o, gpt-3.5-turbo) and
# Anthropic Claude models (claude-3-opus, claude-3-sonnet, etc.).
#
# @example Basic usage
#   service = AiServiceFactory.build("gpt-4o")
#   response = service.chat(conversation_history)
#
# @example Error handling
#   begin
#     service = AiServiceFactory.build("unknown-model")
#   rescue ArgumentError => e
#     Rails.logger.error "Unsupported model: #{e.message}"
#   end
class AiServiceFactory
  # Creates an appropriate AI service instance for the given model.
  #
  # @param ai_model [String] The AI model identifier
  # @return [OpenAiService, ClaudeService] The appropriate service instance
  # @raise [ArgumentError] When the model is not supported
  #
  # @see OpenAiService For GPT model implementations
  # @see ClaudeService For Claude model implementations
  def self.build(ai_model)
    case
    when AiModels.openai_model?(ai_model)
      OpenAiService.new(ai_model)
    when AiModels.anthropic_model?(ai_model)
      ClaudeService.new(ai_model)
    else
      raise ArgumentError, "Unsupported AI model: #{ai_model}. Supported models: #{AiModels::ALL_MODELS.join(', ')}"
    end
  end
end
