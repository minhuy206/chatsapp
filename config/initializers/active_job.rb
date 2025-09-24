# ActiveJob configuration for cleaner development logs
#
# Simple configuration to reduce ActiveJob log verbosity in development

if Rails.env.development?
  # Set ActiveJob log level to only show warnings and errors
  Rails.application.config.after_initialize do
    ActiveJob::Base.logger.level = Logger::WARN if ActiveJob::Base.logger
  end
end
