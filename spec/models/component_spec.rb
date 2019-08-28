require 'rails_helper'

RSpec.describe Component, type: :model do
  context '#to_service_metadata' do
    before(:each) do
      SpComponent.destroy_all
      MsaComponent.destroy_all
    end

    let(:published_at) { Time.now }
    let(:msa_component) { create(:new_msa_component_event).msa_component }
    let(:sp_component) { create(:new_sp_component_event).sp_component }
    let!(:root) { PKI.new }
    let!(:upload_signing_certificate_event_1) do
      UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: msa_component
      )
    end
    let!(:upload_signing_certificate_event_2) do
      UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: msa_component
      )
    end
    let!(:upload_signing_certificate_event_3) do
      UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: sp_component
      )
    end
    let!(:upload_signing_certificate_event_4) do
      UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: sp_component
      )
    end
    let!(:upload_encryption_event_1) do
      event = UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: msa_component
      )
      ReplaceEncryptionCertificateEvent.create(
        component: msa_component,
        encryption_certificate_id: event.certificate.id
      )
      event
    end
    let!(:upload_encryption_event_2) do
      event = UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: sp_component
      )
      ReplaceEncryptionCertificateEvent.create(
        component: sp_component,
        encryption_certificate_id: event.certificate.id
      )
      event
    end
    let!(:msa_service) { create(:service, entity_id: 'https://old-and-boring') }
    let!(:sp_service) { create(:service, entity_id: 'https://new-hotness') }

    it 'publishes all the components and services metadata correctly' do
      msa_component.services << msa_service
      sp_component.services << sp_service
      event_id = Event.first.id

      actual_config = Component.to_service_metadata(event_id, published_at)
      expect(expected_config(event_id)).to eq(actual_config)
    end

    def expected_config(event_id)
      {
        published_at: published_at,
        event_id: event_id,
        connected_services: [
          {
            entity_id: sp_service.entity_id,
            service_provider_id: sp_component.id
          }
        ],
        matching_service_adapters: [
          {
            name: msa_component.name,
            entity_id: msa_component.entity_id,
            encryption_certificate: {
              name: upload_encryption_event_1.certificate.x509.subject.to_s,
              value: upload_encryption_event_1.certificate.value
            },
            signing_certificates: [
              {
                name: upload_signing_certificate_event_2.certificate.x509.subject.to_s,
                value: upload_signing_certificate_event_2.certificate.value
              },
              {
                name: upload_signing_certificate_event_1.certificate.x509.subject.to_s,
                value: upload_signing_certificate_event_1.certificate.value
              }
            ]
          }
        ],
        service_providers: [
          {
            id: sp_component.id,
            encryption_certificate: {
              name: upload_encryption_event_2.certificate.x509.subject.to_s,
              value: upload_encryption_event_2.certificate.value
            },
            name: sp_component.name,
            signing_certificates: [
              {
                name: upload_signing_certificate_event_4.certificate.x509.subject.to_s,
                value: upload_signing_certificate_event_4.certificate.value
              },
              {
                name: upload_signing_certificate_event_3.certificate.x509.subject.to_s,
                value: upload_signing_certificate_event_3.certificate.value
              }
            ]
          }
        ]
      }
    end
  end
end
