class OpenAiService
  def initialize(model = "gpt-4o-mini")
    @model = model
    @client = OpenAI::Client.new(
      access_token: ENV["OPENAI_ACCESS_TOKEN"] ||
        raise("OPENAI_ACCESS_TOKEN environment variable required")
    )
  end

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
    Rails.logger.error "OpenAI API Error: #{e.message}"
    "I apologize, but I'm having trouble processing your request right now. Please try again."
  end

  private

  def format_messages(conversation_history)
    conversation_history.map do |message|
      { role: message.role, content: message.content }
    end
  end
end
