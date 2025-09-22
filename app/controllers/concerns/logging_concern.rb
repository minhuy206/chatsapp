# Logging concern for controllers
module LoggingConcern
  extend ActiveSupport::Concern

  included do
    around_action :log_request_performance
    rescue_from StandardError, with: :log_and_handle_error
  end

  private

  def log_request_performance
    start_time = Time.current

    yield

    duration = (Time.current - start_time) * 1000

    log_performance(
      operation: "#{controller_name}##{action_name}",
      duration: duration.round(2),
      method: request.method,
      path: request.path,
      user_id: current_user&.id,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def log_and_handle_error(error)
    log_error(
      error: error,
      context: {
        controller: controller_name,
        action: action_name,
        params: params.except(:password, :password_confirmation).to_unsafe_h,
        user_id: current_user&.id,
        request_id: request.uuid
      }
    )

    # Re-raise the error to let Rails handle it normally
    raise error
  end

  # Helper method for logging AI interactions in controllers
  def log_ai_request(service:, action:, **metadata)
    start_time = Time.current

    result = yield

    duration = (Time.current - start_time) * 1000

    log_ai_interaction(
      service: service,
      action: action,
      duration: duration.round(2),
      user_id: current_user&.id,
      **metadata
    )

    result
  end

  # Delegate logging methods to LoggerHelper
  def log_error(error:, context: nil, **metadata)
    LoggerHelper.log_error(error: error, context: context, **metadata)
  end

  def log_performance(operation:, duration:, **metadata)
    LoggerHelper.log_performance(operation: operation, duration: duration, **metadata)
  end

  def log_ai_interaction(service:, action:, duration: nil, tokens: nil, **metadata)
    LoggerHelper.log_ai_interaction(
      service: service,
      action: action,
      duration: duration,
      tokens: tokens,
      **metadata
    )
  end

  def log_info(message:, context: nil, **metadata)
    LoggerHelper.log_info(message: message, context: context, **metadata)
  end
end
