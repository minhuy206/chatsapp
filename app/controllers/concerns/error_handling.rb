module Concerns
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from LlmErrors::BaseError, with: :handle_llm_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
      rescue_from StandardError, with: :handle_standard_error

      private

      def handle_llm_error(error)
        log_error(error)

        render json: {
          error: error.to_h,
          timestamp: Time.current
        }, status: determine_http_status(error)
      end

      def handle_not_found(error)
        log_error(error)

        render json: {
          error: {
            type: "NotFoundError",
            message: "Resource not found"
          },
          timestamp: Time.current
        }, status: :not_found
      end

      def handle_validation_error(error)
        log_error(error)

        render json: {
          error: {
            type: "ValidationError",
            message: error.message,
            details: error.record&.errors&.full_messages
          },
          timestamp: Time.current
        }, status: :unprocessable_entity
      end

      def handle_standard_error(error)
        log_error(error, severity: :fatal)

        # Don't leak internal errors in production
        if Rails.env.production?
          render json: {
            error: {
              type: "InternalError",
              message: "An unexpected error occurred. Please try again."
            },
            timestamp: Time.current
          }, status: :internal_server_error
        else
          render json: {
            error: {
              type: error.class.name,
              message: error.message,
              backtrace: error.backtrace&.first(10)
            },
            timestamp: Time.current
          }, status: :internal_server_error
        end
      end

      def determine_http_status(error)
        case error
        when LlmErrors::AuthenticationError
          :unauthorized
        when LlmErrors::RateLimitError
          :too_many_requests
        when LlmErrors::InvalidRequestError
          :bad_request
        when LlmErrors::ModelNotFoundError
          :not_found
        when LlmErrors::ServiceUnavailableError
          :service_unavailable
        when LlmErrors::TimeoutError
          :gateway_timeout
        when LlmErrors::ContentFilterError
          :forbidden
        else
          :internal_server_error
        end
      end

      def log_error(error, severity: :error)
        Rails.logger.public_send(severity, {
          request_id: request.uuid,
          error_class: error.class.name,
          message: error.message,
          controller: self.class.name,
          action: action_name,
          params: filtered_params,
          backtrace: error.backtrace&.first(5)
        }.to_json)
      end

      def filtered_params
        request.filtered_parameters.except(:controller, :action)
      end
    end
  end
end
