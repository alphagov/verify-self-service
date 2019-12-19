module HubEnvironmentConcern
  extend ActiveSupport::Concern

  HEALTHCHECK_ENDPOINT = '/service-status'.freeze
  CERTIFICATES_ROUTE = '/config/certificates/'.freeze
  CERTIFICATE_ENCRYPTION_ENDPOINT = "%{entity_id}/certs/encryption".freeze
  CERTIFICATES_SIGNING_ENDPOINT = "%{entity_id}/certs/signing".freeze

  def hub_environment(environment, value)
    environment = environment
    value = value.to_s
    Rails.configuration.hub_environments.fetch(environment)[value]
  rescue KeyError
    Rails.logger.error("Failed to find #{value} for #{environment}")
    "#{environment}-#{value}"
  end

  def encryption_cert_path(environment, entity_id)
    { environment: environment, url: [hub_environment(environment, :hub_config_host), CERTIFICATES_ROUTE, CERTIFICATE_ENCRYPTION_ENDPOINT % { entity_id: CGI.escape(entity_id) }].join }
  end

  def signing_certs_path(environment, entity_id)
    { environment: environment, url: [hub_environment(environment, :hub_config_host), CERTIFICATES_ROUTE, CERTIFICATES_SIGNING_ENDPOINT % { entity_id: CGI.escape(entity_id) }].join }
  end

  def healthcheck_path(environment)
    { environment: environment, url: [hub_environment(environment, :hub_config_host), HEALTHCHECK_ENDPOINT].join }
  end

  def use_secure_header(environment)
    hub_environment(environment, :secure_header) == 'true'
  end
end
