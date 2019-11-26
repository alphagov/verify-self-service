require 'spec_helper'
require 'rails_helper'
require 'cgi'

describe HubConfigApi do
  let(:hub_config_api) { HubConfigApi.new }
  let(:entity_id) { 'http://www.test-rp.gov.uk/SAML2/MD' }
  let(:wrong_entity_id) { 'wrong-entity-id' }
  let(:encryption_certificate) { 'base64-x509-encryption-cert' }
  let(:signing_certificate_one) { 'base64-x509-signing-cert-one' }
  let(:signing_certificate_two) { 'base64-x509-encryption-cert-two' }
  let(:hub_response_for_encryption) { 
    {
      issuerId: entity_id,
      certificate: encryption_certificate,
      keyUse: 'Encryption',
      federationEntityType: 'RP',
    }
  }

  let(:hub_response_for_signing) { 
    [
      {
        issuerId: entity_id,
        certificate: signing_certificate_one,
        keyUse: 'Signing',
        federationEntityType: 'RP',
      }
    ]
  }

  let(:hub_response_for_signing_when_dual_running) { 
    [
      {
        issuerId: entity_id,
        certificate: signing_certificate_one,
        keyUse: 'Signing',
        federationEntityType: 'RP',
      },
      {
        issuerId: entity_id,
        certificate: signing_certificate_two,
        keyUse: 'Signing',
        federationEntityType: 'RP',
      }
    ]
  }

  describe '#healthcheck' do
    it 'should return service-status from healtheck' do
      stub_request(:get, 'http://config-service.test:80/service-status')
        .to_return(status: 200)

      response = hub_config_api.healthcheck

      expect(response.status).to eq(200)
    end

    it 'should return a non-200 status code when the API responds with an error' do
      stub_request(:get, 'http://config-service.test:80/service-status')
        .to_return(status: 502)

      response = hub_config_api.healthcheck

      expect(response.status).to eq(502)
    end
  end

  describe '#encryption_certificate' do
    it 'should return the encryption certificate' do
      stub_request(:get, "http://config-service.test:80/config/certificates/#{CGI.escape(entity_id)}/certs/encryption")
        .to_return(body: hub_response_for_encryption.to_json)

      response = hub_config_api.encryption_certificate(entity_id)

      expect(response).to eq(encryption_certificate)
    end

    it 'should return nil and log error if certificate not found' do
      stub_request(:get, "http://config-service.test:80/config/certificates/#{CGI.escape(wrong_entity_id)}/certs/encryption")
        .to_return(status: 404, body: "{\"code\":404,\"message\":\"'#{wrong_entity_id}' - No data is configured for this entity.\"}")
      
      expect(Rails.logger).to receive(:error).with("Error getting encryption certificate for entity_id: #{wrong_entity_id}! (Code: 404)")

      response = hub_config_api.encryption_certificate(wrong_entity_id)

      expect(response).to be nil
    end
  end

  describe '#signing_certificates' do
    it 'should return an array of signing certs with one cert when not dual-running' do
      stub_request(:get, "http://config-service.test:80/config/certificates/#{CGI.escape(entity_id)}/certs/signing")
        .to_return(body: hub_response_for_signing.to_json)

      response = hub_config_api.signing_certificates(entity_id)

      expect(response).to eq([signing_certificate_one])
    end

    it 'should return an array of signing certs with two certs when dual-running' do
      stub_request(:get, "http://config-service.test:80/config/certificates/#{CGI.escape(entity_id)}/certs/signing")
        .to_return(body: hub_response_for_signing_when_dual_running.to_json)

      response = hub_config_api.signing_certificates(entity_id)

      expect(response).to eq([signing_certificate_one, signing_certificate_two])
    end

    it 'should return an empty array and log error if wrong entity-id' do
      stub_request(:get, "http://config-service.test:80/config/certificates/#{CGI.escape(wrong_entity_id)}/certs/signing")
        .to_return(status: 404, body: "{\"code\":404,\"message\":\"'#{wrong_entity_id}' - No data is configured for this entity.\"}")

      expect(Rails.logger).to receive(:error).with("Error getting signing certificates for entity_id: #{wrong_entity_id}! (Code: 404)")

      response = hub_config_api.signing_certificates(wrong_entity_id)

      expect(response).to eq([])
    end
  end
end
