class HubConfigApi
  include HubEnvironmentConcern
  require 'cgi'

  def healthcheck(environment)
    build_request(**healthcheck_path(environment))
  end

  def encryption_certificate(environment, entity_id)
    response = build_request(**encryption_cert_path(environment, entity_id))
    if response.success?
      JSON.parse(response.body)['certificate']
    else
      Rails.logger.error("Error getting encryption certificate for entity_id: #{entity_id}! (Code: #{response.status})")
      nil
    end
  end

  def signing_certificates(environment, entity_id)
    response = build_request(**signing_certs_path(environment, entity_id))
    if response.success?
      JSON.parse(response.body).map { |c| c['certificate'] }
    else
      Rails.logger.error("Error getting signing certificates for entity_id: #{entity_id}! (Code: #{response.status})")
      []
    end
  end

private

  def build_request(environment:, url:)
    return Faraday.get(url) unless use_secure_header(environment)

    Faraday.get(url) { |req| req.headers['X-Self-Service-Authentication'] = Rails.configuration.authentication_header }
  end
end
