module HubEnvironmentConcern
  extend ActiveSupport::Concern

  def hub_environment(environment, value)
    environment = environment.to_sym
    value = value.to_sym
    Rails.configuration.hub_environments.fetch(environment)[value]
  rescue KeyError
    Rails.logger.error("Failed to find #{value} for #{environment}")
    "#{environment}-#{value}"
  end
end
