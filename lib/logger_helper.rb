# Logger helper module for use throughout the application
module LoggerHelper
  extend self

  # AI interaction logging
  def log_ai_interaction(service:, action:, duration: nil, tokens: nil, **metadata)
    return unless Rails.application.config.respond_to?(:ai_logger)

    Rails.application.config.ai_logger.tagged("AI", service.to_s.upcase) do |logger|
      logger.info({
        action: action,
        service: service,
        duration_ms: duration,
        tokens: tokens,
        timestamp: Time.current.iso8601,
        **metadata
      }.compact.to_json)
    end
  end

  # Performance logging
  def log_performance(operation:, duration:, **metadata)
    return unless Rails.application.config.respond_to?(:performance_logger)

    Rails.application.config.performance_logger.tagged("PERFORMANCE") do |logger|
      logger.info({
        operation: operation,
        duration_ms: duration,
        timestamp: Time.current.iso8601,
        **metadata
      }.compact.to_json)
    end
  end

  # Error logging
  def log_error(error:, context: nil, **metadata)
    return unless Rails.application.config.respond_to?(:error_logger)

    Rails.application.config.error_logger.tagged("ERROR") do |logger|
      logger.error({
        error_class: error.class.name,
        message: error.message,
        backtrace: error.backtrace&.first(10),
        context: context,
        timestamp: Time.current.iso8601,
        **metadata
      }.compact.to_json)
    end
  end

  # General application logging with context
  def log_info(message:, context: nil, **metadata)
    Rails.logger.tagged("APP") do |logger|
      if Rails.env.production?
        logger.info({
          message: message,
          context: context,
          timestamp: Time.current.iso8601,
          **metadata
        }.compact.to_json)
      else
        logger.info([message, context, metadata.presence].compact.join(" - "))
      end
    end
  end

  # Debug logging (only in development)
  def log_debug(message:, context: nil, **metadata)
    return unless Rails.env.development?

    Rails.logger.tagged("DEBUG") do |logger|
      logger.debug([message, context, metadata.presence].compact.join(" - "))
    end
  end

  # API-specific error logging
  def log_api_error(error:, service:, endpoint: nil, **metadata)
    return unless Rails.application.config.respond_to?(:error_logger)

    error_data = {
      error_class: error.class.name,
      message: error.message,
      service: service,
      endpoint: endpoint,
      timestamp: Time.current.iso8601,
      **metadata
    }

    # Extract API-specific details if available
    if error.respond_to?(:response) && error.response
      response = error.response
      error_data[:api_response] = {
        status: response.is_a?(Hash) ? (response[:status] || response["status"]) : nil,
        body: response.is_a?(Hash) ? (response[:body] || response["body"])&.to_s&.truncate(1000) : nil,
        headers: response.is_a?(Hash) ? LoggerHelper.safe_slice_headers(response[:headers] || response["headers"]) : nil
      }.compact
    end

    # Add authentication specific logging
    if error.message.include?("401") || error.message.include?("unauthorized")
      error_data[:auth_issue] = true
      error_data[:severity] = "critical"
    end

    Rails.application.config.error_logger.tagged("API_ERROR", service.to_s.upcase) do |logger|
      logger.error(error_data.to_json)
    end
  end

  # Benchmark helper for measuring operation duration
  def benchmark(operation_name:, **metadata)
    start_time = Time.current
    result = yield
    duration = (Time.current - start_time) * 1000

    log_performance(
      operation: operation_name,
      duration: duration.round(2),
      **metadata
    )

    result
  rescue => error
    duration = (Time.current - start_time) * 1000
    log_error(
      error: error,
      context: {
        operation: operation_name,
        duration_ms: duration.round(2),
        **metadata
      }
    )
    raise
  end

  private

  def self.safe_slice_headers(headers)
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