require "anthropic"

module Llm
  class AnthropicService < BaseService
    def stream_completion(messages:, model:, &block)
      with_retry(max_attempts: 3) do
        client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

        # Separate system message from conversation
        system_message = messages.find { |msg| msg[:role] == "system" }
        conversation_messages = messages.reject { |msg| msg[:role] == "system" }

        params = {
          model: model,
          max_tokens: max_tokens,
          temperature: temperature,
          messages: conversation_messages
        }

        params[:system] = system_message[:content] if system_message

        stream = client.messages.stream(**params)

        stream.text.each do |text|
          yield text if block_given?
        end
      end
    rescue StandardError => e
      log_error(e, provider: provider_name, model: model)
      handle_provider_error(e, provider: provider_name)
    end
  end
end
