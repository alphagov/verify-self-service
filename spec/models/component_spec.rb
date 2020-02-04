require 'rails_helper'

RSpec.describe Component, type: :model do
  include StubHubConfigApiSupport
  context '#to_service_metadata' do
    before(:each) do
      SpComponent.destroy_all
      MsaComponent.destroy_all
    end
    let(:published_at) { Time.now }
    let(:msa_component) { create(:msa_component) }
    let(:sp_component) { create(:sp_component) }
    let(:root) { PKI.new }
    let!(:upload_signing_certificate_event_1) do
      create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 6.months),
        component: msa_component
      )
    end
    let!(:upload_signing_certificate_event_2) do
      create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 6.months),
        component: msa_component
      )
    end
    let!(:upload_signing_certificate_event_3) do
      create(:assign_sp_component_to_service_event, service: sp_service, sp_component_id: sp_component.id)
      create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 6.months),
        component: sp_component
      )
    end
    let!(:upload_signing_certificate_event_4) do
      create(:assign_sp_component_to_service_event, service: sp_service, sp_component_id: sp_component.id)
      create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: sp_component
      )
    end
    let!(:upload_encryption_event_1) do
      event = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: 6.months),
        component: msa_component
      )
      create(:replace_encryption_certificate_event,
        component: msa_component,
        encryption_certificate_id: event.certificate.id
      )
      event
    end
    let!(:upload_encryption_event_2) do
      create(:assign_sp_component_to_service_event, service: sp_service, sp_component_id: sp_component.id)
      event = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: 3.months),
        component: sp_component
      )
      create(:replace_encryption_certificate_event,
        component: sp_component,
        encryption_certificate_id: event.certificate.id
      )
      event
    end

    let!(:msa_service) { create(:service, entity_id: 'https://old-and-boring') }
    let!(:sp_service) { create(:service, entity_id: 'https://new-hotness') }

    it 'publishes all the components and services metadata correctly for environment' do
      event_id = Event.first.id

      actual_config = Component.to_service_metadata(event_id, 'staging', published_at)
      expect(expected_config(event_id)).to eq(actual_config)
    end

    it 'publishes no components if no components with a given environment' do
      event_id = Event.first.id

      actual_config = Component.to_service_metadata(event_id, 'integration', published_at)
      expect(empty_config(event_id)).to eq(actual_config)
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

    def empty_config(event_id)
      {
        published_at: published_at,
        event_id: event_id,
        connected_services: [],
        matching_service_adapters: [],
        service_providers: []
      }
    end
  end

  context 'sorting certificates' do
    before(:each) do
      SpComponent.destroy_all
      MsaComponent.destroy_all
    end

    let(:root) { PKI.new }
    let(:msa_component) { create(:msa_component) }
    let(:sp_component) { create(:sp_component) }

    def encryption_certificate(expires_in: 129.days, component: )
      @encryption_event = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: expires_in),
        component: component
      )
      create(:replace_encryption_certificate_event,
        component: component,
        encryption_certificate_id: @encryption_event.certificate.id
      ) unless component.encryption_certificate_id == @encryption_event.certificate.id

      @encryption_event.certificate
    end

    it 'maintains order from (lowest to highest) days left' do
      msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 128.days),
        component: msa_component).certificate
      msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 105.days),
        component: msa_component).certificate
      msa_encryption = encryption_certificate(component: msa_component, expires_in: 118.days)

      travel_to Time.now + 100.days

      expect(msa_component.sorted_certificates.map(&:days_left))
        .to eql [105-100, 118-100, 128-100]
      expect(msa_component.sorted_certificates)
        .to eql [msa_secondary, msa_encryption, msa_primary]
    end

    it 'does not maintains order from (lowest to highest) when certificates are not about to expire' do
      msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 360.days),
        component: msa_component).certificate
      msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 345.days),
        component: msa_component).certificate
      msa_encryption = encryption_certificate(component: msa_component, expires_in: 327.days)

      travel_to Time.now + 100.days

      expect(msa_component.sorted_certificates.map(&:days_left))
        .not_to eql [327-100, 345-100, 360-100]
      expect(msa_component.sorted_certificates)
        .not_to eql [msa_encryption, msa_secondary, msa_primary]
    end

    it 'maintains order from (lowest to highest) when signing certificate is disabled' do
      msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 128.days),
        component: msa_component).certificate
      msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 105.days),
        component: msa_component).certificate
      msa_encryption = encryption_certificate(component: msa_component, expires_in: 138.days)

      travel_to Time.now + 100.days

      event = DisableSigningCertificateEvent.create(
        certificate: msa_secondary
      )

      expect(msa_component.sorted_certificates)
        .to eql [msa_primary, msa_encryption]
    end

    it 'maintains order from (lowest to highest) when encryption certificate is replaced' do
      msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 128.days),
        component: msa_component).certificate
      msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 105.days),
        component: msa_component).certificate
      msa_encryption = encryption_certificate(component: msa_component, expires_in: 138.days)

      travel_to Time.now + 100.days

      event = DisableSigningCertificateEvent.create(
        certificate: msa_secondary
      )
      new_encryption_certificate = create(:msa_encryption_certificate)
      create(:replace_encryption_certificate_event,
        component: msa_component,
        encryption_certificate_id: new_encryption_certificate.id
      )

      expect(msa_component.sorted_certificates)
        .to eql [msa_primary, new_encryption_certificate]
    end

    it "shows encryption certificate first, when it's to expire first maintains order (lowest to highest)" do
      msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 364.days),
        component: msa_component).certificate
      msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 122.days),
        component: msa_component).certificate
      msa_encryption = encryption_certificate(expires_in: 104.days, component: msa_component)

      travel_to Time.now + 100.days

      expect(msa_component.sorted_certificates.map(&:days_left))
        .to eql [104-100, 122-100, 364-100]
      expect(msa_component.sorted_certificates)
        .to eql [msa_encryption, msa_secondary, msa_primary]
    end

    it 'orders components according lowest certificate present from (lowest to highest) days_left' do
      zeus_msa = create(:msa_component, name: 'MSA Zeus')
      zeus_sp = create(:sp_component, name: 'SP Zeus')
      aphrodite_msa = create(:msa_component, name: 'MSA Aphrodite')
      aphrodite_sp = create(:sp_component, name: 'SP Aphrodite')

      zeus_sp_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 116.days),
        component: zeus_sp).certificate
      zeus_sp_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 102.days),
        component: zeus_sp).certificate
      zeus_sp_encryption = encryption_certificate(component: zeus_sp, expires_in: 108.days)

      aphrodite_sp_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 364.days),
        component: aphrodite_sp).certificate
      aphrodite_sp_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 125.days),
        component: aphrodite_sp).certificate
      aphrodite_sp_encryption = encryption_certificate(expires_in: 130.days, component: aphrodite_sp)

      aphrodite_msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 364.days),
        component: aphrodite_msa).certificate
      aphrodite_msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 122.days),
        component: aphrodite_msa).certificate
      aphrodite_sp_encryption = encryption_certificate(expires_in: 140.days, component: aphrodite_msa)

      zeus_msa_primary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 128.days),
        component: zeus_msa).certificate
      zeus_msa_secondary = create(:upload_certificate_event,
        usage: CERTIFICATE_USAGE::SIGNING,
        value: root.generate_encoded_cert(expires_in: 105.days),
        component: zeus_msa).certificate
      zeus_msa_encryption = encryption_certificate(component: zeus_msa, expires_in: 138.days)

      travel_to Time.now + 100.days
      components = MsaComponent.where(name: ['MSA Zeus','MSA Aphrodite']) + SpComponent.where(name: ['SP Zeus','SP Aphrodite'])

      expect(components.sort_by(&:days_left)).to eq [zeus_sp, zeus_msa, aphrodite_msa, aphrodite_sp]
      expect(components.sort_by(&:days_left).map(&:days_left)).to eq [2, 5, 22, 25]
    end

    it 'uses a NON-SORTING-SEED value when any component does not contain a certificate' do
      zeus_msa = create(:msa_component, name: 'MSA Zeus')
      zeus_sp = create(:sp_component, name: 'SP Zeus')
      aphrodite_msa = create(:msa_component, name: 'MSA Aphrodite')
      aphrodite_sp = create(:sp_component, name: 'SP Aphrodite')

      travel_to Time.now + 100.days
      components = MsaComponent.where(name: ['MSA Zeus','MSA Aphrodite']) + SpComponent.where(name: ['SP Zeus','SP Aphrodite'])

      expect(components.map(&:sorted_certificates)).to eql [[], [], [], []]
      expect(components.map(&:days_left))
        .to eq [Component::NON_SORTING_SEED, Component::NON_SORTING_SEED, Component::NON_SORTING_SEED, Component::NON_SORTING_SEED]
      expect(components.sort_by(&:days_left)).to eq [zeus_msa, aphrodite_msa, zeus_sp, aphrodite_sp]
    end
  end
end

