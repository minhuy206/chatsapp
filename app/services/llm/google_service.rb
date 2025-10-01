require "faraday"
require "json"

module Llm
  class GoogleService < BaseService
    def stream_completion(messages:, model:, &block)
      with_retry(max_attempts: 3) do
        # Separate system instruction
        system_instruction = messages.find { |msg| msg[:role] == "system" }
        conversation_messages = messages.reject { |msg| msg[:role] == "system" }

        # Format for Gemini API
        contents = conversation_messages.map { |msg|
          {
            role: msg[:role] == "assistant" ? "model" : "user",
            parts: [ { text: msg[:content] } ]
          }
        }

        payload = {
          contents: contents,
          generationConfig: {
            maxOutputTokens: max_tokens,
            temperature: temperature
          }
        }

        payload[:systemInstruction] = { parts: [ { text: system_instruction[:content] } ] } if system_instruction

        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse"

        connection.post(url) do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["x-goog-api-key"] = "#{ENV['GOOGLE_API_KEY']}"
          req.body = payload.to_json

          req.options.on_data = Proc.new do |chunk, _total_bytes, _env|
            process_chunk(chunk, &block)
          end
        end
      end
    rescue StandardError => e
      log_error(e, provider: provider_name, model: model)
      handle_provider_error(e, provider: provider_name)
    end

    private

    def connection
      @connection ||= Faraday.new do |f|
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end

    def process_chunk(chunk, &block)
      chunk.split("\n").each do |line|
        next unless line.start_with?("data: ")

        data = line.sub("data: ", "").strip

        begin
          json = JSON.parse(data)
          text = json.dig("candidates", 0, "content", "parts", 0, "text")
          yield text if text && block_given?
        rescue JSON::ParserError
          next
        end
      end
    end
  end
end
