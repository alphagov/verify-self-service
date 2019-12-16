class HubConfigApi
  include HubEnvironmentConcern
  require 'cgi'
  HEALTHCHECK_ENDPOINT = 'service-status'.freeze
  CERTIFICATES_ROUTE = '/config/certificates/'.freeze
  CERTIFICATE_ENCRYPTION_ENDPOINT = "%{entity_id}/certs/encryption".freeze
  CERTIFICATES_SIGNING_ENDPOINT = "%{entity_id}/certs/signing".freeze

  def healthcheck(environment)
    build_request(**healthcheck_path(environment))
  end

  def encryption_certificate(environment, entity_id)
    response = build_request(**encryption_cert_path(environment, entity_id))
    if response.status == 200
      JSON.parse(response.body)['certificate']
    else
      Rails.logger.error("Error getting encryption certificate for entity_id: #{entity_id}! (Code: #{response.status})")
      nil
    end
  end

  def signing_certificates(environment, entity_id)
    response = build_request(**signing_certs_path(environment, entity_id))
    if response.status == 200
      JSON.parse(response.body).map { |c| c['certificate'] }
    else
      Rails.logger.error("Error getting signing certificates for entity_id: #{entity_id}! (Code: #{response.status})")
      []
    end
  end

private

  def use_secure_header(environment)
    hub_environment(environment, :'secure-header') == 'true'
  end

  def build_request(environment:, url:)
    return Faraday.get(url) unless use_secure_header(environment)

    Faraday.get(url) { |req| req.headers['X-Self-Service-Authentication'] = Rails.configuration.authentication_header }
  end

  def encryption_cert_path(environment, entity_id)
    { environment: environment, url: URI.join(hub_environment(environment, :'hub-config-host'), CERTIFICATES_ROUTE, CERTIFICATE_ENCRYPTION_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s }
  end

  def signing_certs_path(environment, entity_id)
    { environment: environment, url: URI.join(hub_environment(environment, :'hub-config-host'), CERTIFICATES_ROUTE, CERTIFICATES_SIGNING_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s }
  end

  def healthcheck_path(environment)
    { environment: environment, url: URI.join(hub_environment(environment, :'hub-config-host'), HEALTHCHECK_ENDPOINT).to_s }
  end
end
