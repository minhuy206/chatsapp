# Service for handling AI provider-specific errors with centralized logging
class AiErrorHandler
  class << self
    # Main entry point for handling AI errors
    def handle_error(error, context = {})
      error_info = build_error_context(error, context)
      provider = detect_provider(error)

      case provider
      when :openai
        handle_openai_error(error, error_info, context)
      when :anthropic
        handle_anthropic_error(error, error_info, context)
      else
        handle_generic_error(error, error_info, context)
      end

      # Always log the general error for tracking
      LoggerHelper.log_error(error: error, context: error_info)
    end

    private

    def build_error_context(error, context)
      base_context = {
        error_type: error.class.name,
        timestamp: Time.current.iso8601
      }

      # Add API response details if available
      if error.respond_to?(:response) && error.response
        base_context[:api_response] = extract_api_response_details(error.response)
      end

      base_context.merge(context)
    end

    def detect_provider(error)
      error_message = error.message.downcase

      if error_message.include?("openai") || error_message.include?("gpt")
        :openai
      elsif error_message.include?("anthropic") || error_message.include?("claude")
        :anthropic
      elsif error.class.name.downcase.include?("anthropic")
        :anthropic
      else
        :unknown
      end
    end

    def handle_openai_error(error, error_info, context)
      error_info[:api_service] = "openai"

      # Extract OpenAI-specific details
      if error.message.include?("OpenAI API Error")
        endpoint = extract_endpoint_from_error(error.message)
        status = extract_status_from_error(error.message)

        error_info[:api_endpoint] = endpoint if endpoint
        error_info[:http_status] = status if status
      end

      # Log OpenAI-specific error
      LoggerHelper.log_api_error(
        error: error,
        service: :openai,
        endpoint: error_info[:api_endpoint],
        **context.slice(:conversation_id, :job_id, :ai_model, :message_count)
      )

      # Handle authentication errors specifically
      handle_authentication_error(error, error_info, :openai) if authentication_error?(error)
    end

    def handle_anthropic_error(error, error_info, context)
      error_info[:api_service] = "anthropic"

      # Log Anthropic-specific error
      LoggerHelper.log_api_error(
        error: error,
        service: :anthropic,
        **context.slice(:conversation_id, :job_id, :ai_model, :message_count)
      )

      # Handle authentication errors specifically
      handle_authentication_error(error, error_info, :anthropic) if authentication_error?(error)
    end

    def handle_generic_error(error, error_info, context)
      error_info[:api_service] = "unknown"

      # For unknown providers, we still log what we can
      LoggerHelper.log_error(
        error: error,
        context: error_info.merge(
          note: "Unknown AI provider - could not determine specific handling"
        )
      )
    end

    def handle_authentication_error(error, error_info, provider)
      error_info[:auth_issue] = true
      error_info[:severity] = "critical"

      env_var = provider == :openai ? "OPENAI_ACCESS_TOKEN" : "ANTHROPIC_API_KEY"
      service_name = provider == :openai ? "OpenAI" : "Anthropic"

      auth_error = StandardError.new(
        "#{service_name} Authentication Error - Check API key configuration"
      )

      LoggerHelper.log_error(
        error: auth_error,
        context: error_info.merge(
          urgent: true,
          resolution: "Verify #{env_var} environment variable is set correctly",
          api_key_present: ENV[env_var].present?,
          api_key_length: ENV[env_var]&.length
        )
      )
    end

    def authentication_error?(error)
      error_message = error.message.downcase
      error_message.include?("401") ||
      error_message.include?("unauthorized") ||
      error_message.include?("status 401")
    end

    def extract_api_response_details(response)
      return {} unless response

      if response.is_a?(Hash)
        {
          status: response[:status] || response["status"],
          body: (response[:body] || response["body"])&.to_s&.truncate(500),
          headers: safe_slice_headers(response[:headers] || response["headers"])
        }.compact
      else
        {}
      end
    end

    def extract_endpoint_from_error(error_message)
      # Extract URL from error message like "POST https://api.openai.com/v1/chat/completions"
      match = error_message.match(/POST\s+(https?:\/\/[^\s]+)/)
      match ? match[1] : nil
    end

    def extract_status_from_error(error_message)
      # Extract status code from error message like "status 401"
      match = error_message.match(/status\s+(\d+)/)
      match ? match[1].to_i : nil
    end

    def safe_slice_headers(headers)
      return nil unless headers.respond_to?(:[])

      begin
        if headers.is_a?(Hash)
          headers.slice("content-type", "x-request-id", "cf-ray")
        else
          nil
        end
      rescue
        nil
      end
    end
  end
end
