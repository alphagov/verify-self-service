require 'rails_helper'
require 'json'
require 'securerandom'
RSpec.describe Component, type: :model do
  include CertificateSupport
  context '#to_service_metadata' do
    before(:each) do
      Component.destroy_all
    end
    let(:root) { PKI.new }
    let(:published_at) { Time.now }
    let(:event_id) { 0 }
    let(:certificate) { root.generate_encoded_cert(expires_in: 2.months) }
    entity_id = SecureRandom.hex(10)
    component_name = 'test component'
    component_params = { component_type: 'MSA', name: component_name, entity_id: entity_id }
    let(:component) { NewComponentEvent.create(component_params).component }
    let(:root) { PKI.new }
    let(:x509_cert_1) { root.generate_encoded_cert(expires_in: 2.months) }
    let(:x509_cert_2) { root.generate_encoded_cert(expires_in: 9.months) }
    let(:x509_cert_3) { root.generate_encoded_cert(expires_in: 9.months) }
    let(:upload_signing_event) do
      UploadCertificateEvent.create(
        usage: CONSTANTS::SIGNING, value: x509_cert_1, component_id: component.id
      )
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
    end

    it 'is an MSA component with signing and encryption certs' do
      upload_signing_event
      upload_encryption_event
      actual_config = Component.to_service_metadata(
        event_id: event_id,
        entity_id: entity_id,
        published_at: published_at
      )
  
      expected_config = {
        published_at: published_at,
        entity_id: entity_id,
        event_id: event_id,
        matching_service_adapters: [{
          name: component_name,
          encryption_certificate: {
            name: certificate_subject(x509_cert_3),
            value: x509_cert_3
          },
          signing_certificates: [{
            name: certificate_subject(x509_cert_1),
            value: x509_cert_1
          }, {
            name: certificate_subject(x509_cert_2),
            value: x509_cert_2
          }]
        }],
        service_providers: []
      }

      expect(actual_config).to include(:matching_service_adapters)
      expect(actual_config).to include(expected_config)
    end

    it 'produces required output structure' do
      Component.destroy_all
      actual_config = Component.to_service_metadata(event_id: event_id,
                                                    entity_id: entity_id,
                                                    published_at: published_at)
      expected_config = {
        entity_id: entity_id,
        published_at: published_at,
        event_id: event_id,
        matching_service_adapters: [],
        service_providers: []
      }
      expect(actual_config).to include(:published_at, :service_providers)
      expect(actual_config).to eq(expected_config)
    end

    it 'entity id is required MSA component' do
      component_params = {
        component_type: 'MSA',
        name: component_name
      }
      new_component = NewComponentEvent.create(component_params).component
      expect(new_component).not_to be_persisted
    end

    it 'can set entity id on MSA component' do
      component_params = {
        component_type: 'MSA',
        name: component_name,
        entity_id: entity_id
      }
      new_component = NewComponentEvent.create(component_params).component
      expect(new_component).to be_persisted
    end

    it 'cannot set entity id on VSP component' do
      component_params = {
        component_type: 'VSP',
        name: component_name,
        entity_id: entity_id
      }
      new_component = NewComponentEvent.create(component_params).component
      expect(new_component).not_to be_persisted
    end

    it 'entity id not required on VSP component' do
      component_params = {
        component_type: 'VSP',
        name: component_name
      }
      new_component = NewComponentEvent.create(component_params).component
      expect(new_component).to be_persisted
    end
  end
end
