module LlmErrors
  # Default retry-after values in seconds
  DEFAULT_RETRY_AFTER = 60
  SERVICE_UNAVAILABLE_RETRY_AFTER = 30

  # Base error class for all LLM-related errors
  class BaseError < StandardError
    attr_reader :provider, :original_error, :retry_after

    def initialize(message, provider: nil, original_error: nil, retry_after: nil)
      @provider = provider
      @original_error = original_error
      @retry_after = validate_retry_after(retry_after)
      super(message)
    end

    def retryable?
      false
    end

    def user_message
      "An error occurred while processing your request. Please try again."
    end

    def error_code
      "llm_#{self.class.name.demodulize.underscore}"
    end

    def to_h
      {
        error: self.class.name.demodulize,
        code: error_code,
        message: user_message,
        provider: provider,
        retry_after: retry_after
      }.compact
    end

    private

    def validate_retry_after(value)
      return nil if value.nil?
      [value.to_i, 0].max  # Ensure non-negative
    end
  end

  # Provider communication errors (network, timeout)
  class ProviderError < BaseError
    def retryable?
      true
    end

    def user_message
      "Unable to connect to AI service. Please try again in a moment."
    end
  end

  # Authentication/API key errors
  class AuthenticationError < BaseError
    def user_message
      "AI service authentication failed. Please contact support."
    end
  end

  # Rate limit errors
  class RateLimitError < BaseError
    def initialize(message, **options)
      super(message, retry_after: options[:retry_after] || DEFAULT_RETRY_AFTER, **options)
    end

    def retryable?
      true
    end

    def user_message
      "AI service rate limit reached. Please try again in #{retry_after} seconds."
    end
  end

  # Request timeout errors
  class TimeoutError < ProviderError
    def user_message
      "Request took too long. Please try again."
    end
  end

  # Invalid request errors (bad parameters)
  class InvalidRequestError < BaseError
    def user_message
      "Invalid request parameters. Please check your input."
    end
  end

  # Service unavailable errors
  class ServiceUnavailableError < ProviderError
    def initialize(message, **options)
      super(message, retry_after: options[:retry_after] || SERVICE_UNAVAILABLE_RETRY_AFTER, **options)
    end

    def user_message
      "AI service is temporarily unavailable. Please try again in a moment."
    end
  end

  # Model not found or unsupported
  class ModelNotFoundError < BaseError
    def user_message
      "The requested AI model is not available."
    end
  end

  # Content filtering/safety errors
  class ContentFilterError < BaseError
    def user_message
      "Your request was blocked by content filters. Please modify your message."
    end
  end

  # Streaming errors
  class StreamingError < ProviderError
    def user_message
      "Error occurred during response streaming. Please try again."
    end
  end
end
