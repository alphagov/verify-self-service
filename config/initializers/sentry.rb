Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.transport_failure_callback = ->(event) { Rails.logger.error(event.to_s) }
  config.environments = %w[production]
end
