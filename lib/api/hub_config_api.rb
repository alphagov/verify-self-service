class HubConfigApi
  require 'cgi'

  HUB_HOST = Rails.configuration.hub_config_host
  HEALTHCHECK_ENDPOINT = 'service-status'.freeze
  CERTIFICATES_ROUTE = '/config/certificates/'.freeze
  CERTIFICATE_ENCRYPTION_ENDPOINT = "%{entity_id}/certs/encryption".freeze
  CERTIFICATES_SIGNING_ENDPOINT = "%{entity_id}/certs/signing".freeze

  def initialize; end

  def healthcheck
    Faraday.get healthcheck_path
  end

  def encryption_certificate(entity_id)
    response = Faraday.get encryption_cert_path(entity_id)
    if response.status == 200
      JSON.parse(response.body)['certificate']
    else
      Rails.logger.error("Error getting encryption certificate for entity_id: #{entity_id}! (Code: #{response.status})")
      nil
    end
  end

  def signing_certificates(entity_id)
    response = Faraday.get signing_certs_path(entity_id)
    if response.status == 200
      JSON.parse(response.body).map { |c| c['certificate'] }
    else
      Rails.logger.error("Error getting signing certificates for entity_id: #{entity_id}! (Code: #{response.status})")
      []
    end
  end

private

  def encryption_cert_path(entity_id)
    URI.join(HUB_HOST, CERTIFICATES_ROUTE, CERTIFICATE_ENCRYPTION_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s
  end

  def signing_certs_path(entity_id)
    URI.join(HUB_HOST, CERTIFICATES_ROUTE, CERTIFICATES_SIGNING_ENDPOINT % { entity_id: CGI.escape(entity_id) }).to_s
  end

  def healthcheck_path
    URI.join(HUB_HOST, HEALTHCHECK_ENDPOINT).to_s
  end
end
