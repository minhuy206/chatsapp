module Concerns
  module Retryable
    extend ActiveSupport::Concern

    included do
      # Execute block with retry logic and exponential backoff
      # @param max_attempts [Integer] Maximum number of retry attempts
      # @param initial_delay [Float] Initial delay in seconds
      # @param max_delay [Float] Maximum delay in seconds
      # @param backoff_multiplier [Float] Multiplier for exponential backoff
      # @yield Block to execute with retry logic
      def with_retry(max_attempts: 3, initial_delay: 1.0, max_delay: 30.0, backoff_multiplier: 2.0)
        attempts = 0
        delay = initial_delay

        begin
          attempts += 1
          yield
        rescue StandardError => e
          # Only retry if error is retryable
          if should_retry?(e, attempts, max_attempts)
            log_retry(e, attempts, delay)
            # Add jitter to prevent thundering herd
            jitter = delay * rand(0.0..0.25)
            actual_delay = delay + jitter
            sleep(actual_delay)
            delay = [delay * backoff_multiplier, max_delay].min
            retry
          else
            raise
          end
        end
      end

      private

      def should_retry?(error, attempts, max_attempts)
        return false if attempts >= max_attempts

        # Check if error is retryable
        if error.respond_to?(:retryable?)
          error.retryable?
        else
          # Default: retry on network errors
          error.is_a?(LlmErrors::ProviderError) ||
            error.is_a?(LlmErrors::TimeoutError) ||
            error.is_a?(LlmErrors::ServiceUnavailableError)
        end
      end

      def log_retry(error, attempt, delay)
        Rails.logger.warn({
          message: "Retrying after error",
          error: error.class.name,
          attempt: attempt,
          delay: delay,
          error_message: error.message
        }.to_json)
      end
    end
  end
end
