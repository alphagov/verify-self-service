require 'rails_helper'
require 'json'
RSpec.describe Component, type: :model do
  context '#to_service_metadata' do
    before(:each) do
      Component.destroy_all
    end
    let(:root) { PKI.new }
    let(:published_at) { Time.now }
    let(:event_id) { 0 }
    let(:certificate) { root.generate_encoded_cert(expires_in: 2.months) }

    component_name = 'test component'
    component_params = { component_type: 'MSA', name: component_name }
    let(:component) { NewComponentEvent.create(component_params).component }
    let(:root) { PKI.new }
    let(:x509_cert_1) { root.generate_encoded_cert(expires_in: 2.months) }
    let(:x509_cert_2) { root.generate_encoded_cert(expires_in: 9.months) }
    let(:x509_cert_3) { root.generate_encoded_cert(expires_in: 9.months) }
    let(:upload_signing_certificate_event_1) do
      UploadCertificateEvent.create(
        usage: CONSTANTS::SIGNING, value: x509_cert_1, component_id: component.id
      )
    end
    let(:upload_signing_certificate_event_2) do
      UploadCertificateEvent.create(
        usage: CONSTANTS::SIGNING, value: x509_cert_2, component_id: component.id
      )
    end
  
    let(:upload_encryption_event) do
      event = UploadCertificateEvent.create(
        usage: CONSTANTS::ENCRYPTION, value: x509_cert_3, component_id: component.id
      )
      ReplaceEncryptionCertificateEvent.create(
        component: component,
        encryption_certificate_id: event.certificate.id
      )
      event
    end

    it 'is an MSA component with signing and encryption certs' do
      signing1 = upload_signing_certificate_event_1
      signing2 = upload_signing_certificate_event_2
      encryption = upload_encryption_event
      actual_config = Component.to_service_metadata(event_id, published_at)
  
      expected_config = {
        published_at: published_at,
        event_id: event_id,
        matching_service_adapters: [{
          name: component_name,
          encryption_certificate: {
            name: encryption.certificate.x509.subject.to_s,
            value: encryption.certificate.value
          },
          signing_certificates: [{
            name: signing1.certificate.x509.subject.to_s,
            value: signing1.certificate.value
          }, {
            name: signing2.certificate.x509.subject.to_s,
            value: signing2.certificate.value
          }]
        }],
        service_providers: []
      }

      expect(actual_config).to include(:matching_service_adapters)
      expect(actual_config).to include(expected_config)
    end

    it 'produces required output structure' do
      Component.destroy_all
      actual_config = Component.to_service_metadata(event_id, published_at)
      expected_config = {
        published_at: published_at,
        event_id: event_id,
        matching_service_adapters: [],
        service_providers: []
      }
      expect(actual_config).to include(:published_at, :service_providers)
      expect(actual_config).to eq(expected_config)
    end
  end
end
