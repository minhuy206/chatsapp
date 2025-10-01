module Concerns
  module ErrorHandler
    extend ActiveSupport::Concern

    included do
      # Default retry-after value in seconds
      DEFAULT_RETRY_AFTER = 60

      # Map provider-specific errors to our custom errors
      def handle_provider_error(error, provider:)
        # Guard: Don't re-wrap our own errors
        raise error if error.is_a?(LlmErrors::BaseError)

        case error
        when OpenAI::Errors::APIConnectionError, Anthropic::Errors::APIConnectionError
          raise LlmErrors::ProviderError.new(
            "Connection failed: #{error.message}",
            provider: provider,
            original_error: error
          )

        when OpenAI::Errors::RateLimitError, Anthropic::Errors::RateLimitError
          retry_after = extract_retry_after(error)
          raise LlmErrors::RateLimitError.new(
            "Rate limit exceeded",
            provider: provider,
            original_error: error,
            retry_after: retry_after
          )

        when OpenAI::Errors::AuthenticationError, Anthropic::Errors::AuthenticationError
          raise LlmErrors::AuthenticationError.new(
            "Authentication failed: #{error.message}",
            provider: provider,
            original_error: error
          )

        when OpenAI::Errors::APITimeoutError, Anthropic::Errors::APITimeoutError
          raise LlmErrors::TimeoutError.new(
            "Request timeout: #{error.message}",
            provider: provider,
            original_error: error
          )

        when OpenAI::Errors::APIStatusError, Anthropic::Errors::APIStatusError
          handle_status_error(error, provider)

        when Faraday::Error
          handle_faraday_error(error, provider)

        else
          # Generic error fallback
          raise LlmErrors::ProviderError.new(
            "Provider error: #{error.message}",
            provider: provider,
            original_error: error
          )
        end
      end

      private

      def handle_status_error(error, provider)
        status = error.respond_to?(:status) ? error.status : error.response&.status

        case status
        when 400
          raise LlmErrors::InvalidRequestError.new(
            "Invalid request: #{error.message}",
            provider: provider,
            original_error: error
          )
        when 404
          raise LlmErrors::ModelNotFoundError.new(
            "Model not found: #{error.message}",
            provider: provider,
            original_error: error
          )
        when 503
          raise LlmErrors::ServiceUnavailableError.new(
            "Service unavailable",
            provider: provider,
            original_error: error
          )
        else
          raise LlmErrors::ProviderError.new(
            "HTTP #{status}: #{error.message}",
            provider: provider,
            original_error: error
          )
        end
      end

      def handle_faraday_error(error, provider)
        case error
        when Faraday::TimeoutError
          raise LlmErrors::TimeoutError.new(
            "Request timeout",
            provider: provider,
            original_error: error
          )
        when Faraday::ConnectionFailed
          raise LlmErrors::ProviderError.new(
            "Connection failed",
            provider: provider,
            original_error: error
          )
        else
          raise LlmErrors::ProviderError.new(
            "Network error: #{error.message}",
            provider: provider,
            original_error: error
          )
        end
      end

      def extract_retry_after(error)
        # Try to extract retry_after from headers or response
        if error.respond_to?(:response) && error.response
          error.response.headers&.[]("Retry-After")&.to_i || DEFAULT_RETRY_AFTER
        else
          DEFAULT_RETRY_AFTER
        end
      end

      def log_error(error, context = {})
        Rails.logger.error({
          error_class: error.class.name,
          message: error.message,
          provider: error.respond_to?(:provider) ? error.provider : nil,
          backtrace: error.backtrace&.first(5),
          **context
        }.to_json)
      end
    end
  end
end
