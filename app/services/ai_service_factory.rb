class AiServiceFactory
  def self.build(ai_model)
    case ai_model
    when "gpt-4", "gpt-4o", "gpt-3.5-turbo"
      OpenAiService.new(ai_model)
    when "claude-3-opus", "claude-3-sonnet", "claude-3-haiku", "claude-3.5-sonnet"
      ClaudeService.new(ai_model)
    else
      raise ArgumentError, "Unsupported AI model: #{ai_model}"
    end
  end
end
