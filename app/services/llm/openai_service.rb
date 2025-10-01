require "openai"

module Llm
  class OpenaiService < BaseService
    def stream_completion(messages:, model:, &block)
      with_retry(max_attempts: 3) do
        client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])

        stream = client.chat.completions.stream_raw(
          messages: messages,
          model: model,
          max_tokens: max_tokens,
          temperature: temperature
        )

        stream.each do |completion|
          content = completion.dig("choices", 0, "delta", "content")
          yield content if content && block_given?
        end
      end
    rescue StandardError => e
      log_error(e, provider: provider_name, model: model)
      handle_provider_error(e, provider: provider_name)
    end
  end
end
