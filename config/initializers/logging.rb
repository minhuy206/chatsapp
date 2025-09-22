# Enhanced logging configuration for Chatsapp
Rails.application.configure do
  # Custom log formatter for structured logging
  class StructuredLogFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      {
        timestamp: time.iso8601,
        level: severity,
        pid: Process.pid,
        thread: Thread.current.name || Thread.current.object_id,
        app: "chatsapp",
        message: msg.is_a?(String) ? msg : msg.inspect
      }.to_json + "\n"
    end
  end

  # Configure custom loggers for different components
  unless Rails.env.test?
    # Application logger with structured format
    config.logger = ActiveSupport::TaggedLogging.new(
      Logger.new(Rails.root.join("log", "#{Rails.env}.log")).tap do |logger|
        logger.formatter = Rails.env.production? ? StructuredLogFormatter.new : nil
        logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
      end
    )

    # AI Service logger for tracking AI interactions
    ai_logger = Logger.new(Rails.root.join("log", "ai_#{Rails.env}.log"))
    ai_logger.formatter = StructuredLogFormatter.new
    ai_logger.level = Logger::INFO
    Rails.application.config.ai_logger = ActiveSupport::TaggedLogging.new(ai_logger)

    # Performance logger for tracking slow operations
    performance_logger = Logger.new(Rails.root.join("log", "performance_#{Rails.env}.log"))
    performance_logger.formatter = StructuredLogFormatter.new
    performance_logger.level = Logger::INFO
    Rails.application.config.performance_logger = ActiveSupport::TaggedLogging.new(performance_logger)

    # Error logger for tracking application errors
    error_logger = Logger.new(Rails.root.join("log", "errors_#{Rails.env}.log"))
    error_logger.formatter = StructuredLogFormatter.new
    error_logger.level = Logger::WARN
    Rails.application.config.error_logger = ActiveSupport::TaggedLogging.new(error_logger)
  end
end

# Add custom log levels for jobs and other non-controller classes
module LoggingExtensions
  def log_ai_interaction(service:, action:, duration: nil, tokens: nil, **metadata)
    LoggerHelper.log_ai_interaction(
      service: service,
      action: action,
      duration: duration,
      tokens: tokens,
      **metadata
    )
  end

  def log_performance(operation:, duration:, **metadata)
    LoggerHelper.log_performance(operation: operation, duration: duration, **metadata)
  end

  def log_error(error:, context: nil, **metadata)
    LoggerHelper.log_error(error: error, context: context, **metadata)
  end

  def log_info(message:, context: nil, **metadata)
    LoggerHelper.log_info(message: message, context: context, **metadata)
  end
end