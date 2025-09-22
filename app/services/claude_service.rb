class ClaudeService
  def initialize(model = "claude-3-sonnet")
    @model = model_mapping(model)
    @client = Anthropic::Client.new(access_token: Rails.application.credentials.anthropic_api_key)
  end

  def chat(conversation_history)
    response = @client.messages(
      parameters: {
        model: @model,
        max_tokens: 1000,
        messages: format_messages(conversation_history)
      }
    )

    response["content"].first["text"]
  rescue StandardError => e
    Rails.logger.error "Claude API Error: #{e.message}"
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
        role: message.role,
        content: message.content
      }
    end
  end
end
