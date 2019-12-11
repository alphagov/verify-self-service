class HubConfigApi
  require 'cgi'
  HEALTHCHECK_ENDPOINT = 'service-status'.freeze
  CERTIFICATES_ROUTE = '/config/certificates/'.freeze
  CERTIFICATE_ENCRYPTION_ENDPOINT = "%{entity_id}/certs/encryption".freeze
  CERTIFICATES_SIGNING_ENDPOINT = "%{entity_id}/certs/signing".freeze

  def initialize(environment: :test)
    @environment = environment
    @header = hub_environment(:secure_header) == 'true'
    @hub_host = hub_environment(:url)
    @service_authentication_header = ENV['SELF_SERVICE_AUTHENTICATION_HEADER']
  end

  def healthcheck
    build_request(healthcheck_path)
  end

  def encryption_certificate(entity_id)
    response = build_request(encryption_cert_path(entity_id))
    if response.status == 200
      JSON.parse(response.body)['certificate']
    else
      Rails.logger.error("Error getting encryption certificate for entity_id: #{entity_id}! (Code: #{response.status})")
      nil
    end
  end

  def signing_certificates(entity_id)
    response = build_request(signing_certs_path(entity_id))
    if response.status == 200
      JSON.parse(response.body).map { |c| c['certificate'] }
    else
      Rails.logger.error("Error getting signing certificates for entity_id: #{entity_id}! (Code: #{response.status})")
      []
    end
  end

private

  def build_request(url)
    return Faraday.get(url) unless @header

    Faraday.get(url) { |req| req.headers['X-Self-Service-Authentication'] = @service_authentication_header }
  end

  def encryption_cert_path(entity_id)
    URI.join(@hub_host, CERTIFICATES_ROUTE, CERTIFICATE_ENCRYPTION_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s
  end

  def signing_certs_path(entity_id)
    URI.join(@hub_host, CERTIFICATES_ROUTE, CERTIFICATES_SIGNING_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s
  end

  def healthcheck_path
    URI.join(@hub_host, HEALTHCHECK_ENDPOINT).to_s
  end

  def hub_environment(value)
    Rails.configuration.hub_environments.fetch(@environment)[value]
  rescue KeyError
    Rails.logger.error("Failed to find #{value} for #{@environment}")
    "#{environment}-#{value}"
  end
end
