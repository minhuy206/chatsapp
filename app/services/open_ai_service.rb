# OpenAI GPT service for chat completions.
#
# Handles communication with OpenAI's GPT models including gpt-4, gpt-4o, and gpt-3.5-turbo.
# Requires OPENAI_ACCESS_TOKEN environment variable to be set.
#
# @example Basic usage
#   service = OpenAiService.new("gpt-4o")
#   response = service.chat(conversation_messages)
#
# @example Custom configuration
#   service = OpenAiService.new("gpt-3.5-turbo")
#   service.chat(messages) # Returns AI response text
class OpenAiService
  # Initialize the OpenAI service with specified model.
  #
  # @param model [String] The GPT model to use (default: "gpt-4o-mini")
  # @raise [RuntimeError] When OPENAI_ACCESS_TOKEN environment variable is missing
  def initialize(model = "gpt-4o-mini")
    @model = model
    @client = OpenAI::Client.new(
      access_token: ENV["OPENAI_ACCESS_TOKEN"] ||
        raise("OPENAI_ACCESS_TOKEN environment variable required")
    )
  end

  # Generate chat completion using OpenAI GPT models.
  #
  # @param conversation_history [Array<Message>] Array of conversation messages
  # @return [String] The AI-generated response text
  # @raise [StandardError] When API call fails or returns invalid response
  def chat(conversation_history)
    response = @client.chat(
      parameters: {
        model: @model,
        messages: format_messages(conversation_history),
        temperature: 0.7,
        max_tokens: 100
      }
    )

    response.dig("choices", 0, "message", "content")
  rescue StandardError => e
    # Enhanced error context for better debugging and monitoring
    error_context = {
      service: "openai",
      model: @model,
      message_count: conversation_history.size,
      conversation_length: conversation_history.sum { |msg| msg.content&.length || 0 },
      timestamp: Time.current.iso8601
    }

    # Use centralized error handling if available
    if defined?(AiErrorHandler)
      AiErrorHandler.handle_error(e, error_context)
    else
      Rails.logger.error "OpenAI API Error: #{e.message} | Context: #{error_context}"
    end

    "I apologize, but I'm having trouble processing your request right now. Please try again."
  end

  private

  def format_messages(conversation_history)
    conversation_history.map do |message|
      { role: message.role, content: message.content }
    end
  end
end
