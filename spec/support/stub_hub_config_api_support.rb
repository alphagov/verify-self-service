module StubHubConfigApiSupport
  include HubEnvironmentConcern
  AUTHENTICATION_HEADER = { 'X-Self-Service-Authentication': Rails.configuration.authentication_header }.freeze

  def stub_healthcheck_hub_request(environment:, secure_header: false)
    stub = stub_request(:get, healthcheck_path(environment)[:url])
    return stub.with(headers: AUTHENTICATION_HEADER) if secure_header

    stub
  end

  def stub_encryption_certificate_hub_request(environment:, entity_id:, secure_header: false)
    stub = stub_request(:get, encryption_cert_path(environment, entity_id)[:url])
    return stub.with(headers: AUTHENTICATION_HEADER) if secure_header

    stub
  end

  def stub_signing_certificates_hub_request(environment:, entity_id:, secure_header: false)
    stub = stub_request(:get, signing_certs_path(environment, entity_id)[:url])
    return stub.with(headers: AUTHENTICATION_HEADER) if secure_header

    stub
  end

  def hub_response_for_signing(entity_id:, value:)
    [{
      issuerId: entity_id,
      certificate: value,
      keyUse: 'Signing',
      federationEntityType: 'RP',
    }].to_json
  end

  def hub_response_for_encryption(entity_id:, value:)
    {
      issuerId: entity_id,
      certificate: value,
      keyUse: 'Signing',
      federationEntityType: 'RP',
    }.to_json
  end
end
