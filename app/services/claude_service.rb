# Anthropic Claude service for chat completions.
#
# Handles communication with Anthropic's Claude models including claude-3-opus,
# claude-3-sonnet, claude-3-haiku, and claude-3.5-sonnet.
# Requires anthropic_api_key to be configured in Rails credentials.
#
# @example Basic usage
#   service = ClaudeService.new("claude-3.5-sonnet")
#   response = service.chat(conversation_messages)
#
# @example Model selection
#   service = ClaudeService.new("claude-3-opus") # Most capable
#   service = ClaudeService.new("claude-3-haiku") # Fastest
class ClaudeService
  # Initialize the Claude service with specified model.
  #
  # @param model [String] The Claude model to use (default: "claude-3-sonnet")
  def initialize(model = "claude-3-sonnet")
    @model = model_mapping(model)
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"] ||
        raise("ANTHROPIC_API_KEY environment variable required"))
  end

  # Generate chat completion using Anthropic Claude models.
  #
  # @param conversation_history [Array<Message>] Array of conversation messages
  # @return [String] The AI-generated response text
  # @raise [StandardError] When API call fails or returns invalid response
  def chat(conversation_history)
    response = @client.messages.create(
        model: @model,
        max_tokens: 1000,
        messages: format_messages(conversation_history)
    )

    response["content"].first["text"]
  rescue StandardError => e
    # Enhanced error context for better debugging and monitoring
    error_context = {
      service: "anthropic",
      model: @model,
      message_count: conversation_history.size,
      conversation_length: conversation_history.sum { |msg| msg.content&.length || 0 },
      timestamp: Time.current.iso8601
    }

    # Always log immediately for development visibility
    Rails.logger.error "🚨 CLAUDE ERROR CAUGHT: #{e.message}"
    Rails.logger.error "📊 Claude Context: #{error_context.to_json}"

    # Also log the error class and backtrace for debugging
    if Rails.env.development?
      Rails.logger.error "🔍 Error Class: #{e.class.name}"
      Rails.logger.error "🔍 Backtrace: #{e.backtrace&.first(3)&.join("\n")}"
    end

    # Use centralized error handling for additional processing
    if defined?(AiErrorHandler)
      AiErrorHandler.handle_error(e, error_context)
    end

    "I apologize, but I'm having trouble processing your request right now. Please try again in a moment."
  end

  private

  def model_mapping(model)
    case model
    when "claude-3-opus"
      "claude-3-opus-20240229"
    when "claude-3-sonnet"
      "claude-3-sonnet-20240229"
    when "claude-3-haiku"
      "claude-3-haiku-20240307"
    when "claude-3.5-sonnet"
      "claude-3-5-sonnet-20240620"
    else
      model
    end
  end

  def format_messages(conversation_history)
    conversation_history.map do |message|
      {
        "role" => message.role,
        "content" => message.content
      }
    end
  end
end
