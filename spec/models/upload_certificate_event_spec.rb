require 'rails_helper'

RSpec.describe UploadCertificateEvent, type: :model do
  include CertificateSupport

  root = PKI.new
  entity_id = 'http://test-entity-id'
  good_cert_value = root.generate_encoded_cert(expires_in: 2.months)
  component = NewMsaComponentEvent.create(
    name: 'fake_name', entity_id: entity_id, environment: 'staging'
  ).msa_component

  let(:msa_component) { create(:msa_component) }

  include_examples 'has data attributes', UploadCertificateEvent, %i[usage value component_id component_type]
  include_examples 'is aggregated', UploadCertificateEvent, usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_value, component_id: component.id, component_type: component.component_type
  include_examples 'is a creation event', UploadCertificateEvent, usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_value, component_id: component.id, component_type: component.component_type

  context '#value' do
    it 'must be present' do
      event = UploadCertificateEvent.create
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['is not a valid x509 certificate']
    end
  end

  context '#certificate' do
    let(:root) { PKI.new }

    it 'must error with invalid x509 certificate' do
      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: 'Not a valid certificate', component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['is not a valid x509 certificate']
    end

    it 'must allow base64 encoded DER format x509 certificate' do
      cert = root.generate_encoded_cert(expires_in: 2.months)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert, component: msa_component)
      expect(event.certificate.value).to eql(cert)
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must allow PEM format x509 certificate and be stored as base64 encoded DER' do
      cert = root.generate_signed_cert(expires_in: 2.months)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert.to_pem, component: msa_component)
      expect(event.certificate.value).to eql(Base64.strict_encode64(cert.to_der))
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must not be expired' do
      cert = root.generate_encoded_cert(expires_in: -1.months)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['has expired']
    end

    it 'must not expire within 1 month' do
      cert = root.generate_encoded_cert(expires_in: 15.days)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['expires too soon']
    end

    it 'must expire within 1 year' do
      cert = root.generate_encoded_cert(expires_in: 2.years)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['valid for too long']
    end

    it 'must be RSA' do
      cert = root.generate_signed_ec_cert(6.months)

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert.to_pem, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['in not RSA']
    end

    it 'must be at least 2048 bits' do
      cert = root.generate_signed_rsa_cert_and_key(size: 1024)[0]

      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: cert.to_pem, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['key size is less than 2048']
    end
  end

  context '#usage' do
    it 'must be present' do
      event = UploadCertificateEvent.create
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'must be signing or encryption' do
      event = UploadCertificateEvent.create(usage: 'foobar', component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'happy when signing' do
      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end

    it 'happy when encryption' do
      event = UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::ENCRYPTION, component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end
  end

  context "#component" do
    it 'refreshes when component changes' do
      event = UploadCertificateEvent.new(component: msa_component)
      expect(event.component).to eql msa_component
      second_component = create(:msa_component)

      event.component = second_component
      expect(event.component).to_not eql component
      expect(event.component).to eql second_component
    end
  end

  context '#component=' do
    it 'will set component_id and component_type when called during ::create' do
      event = UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::SIGNING,
        component_id: msa_component.id,
        component_type: msa_component.component_type
      )
      expect(event.component).to eql msa_component
    end

    it 'will set component_id when called directly' do
      event = UploadCertificateEvent.new
      event.component = msa_component
      expect(event.component).to eql msa_component
      expect(event.component_id).to eql msa_component.id
    end

    it 'must be invalid when component is new' do
      event = UploadCertificateEvent.create(component: SpComponent.new)
      expect(event).to_not be_valid
      expect(event.errors[:component]).to eql ['must exist']
    end

    it 'must be persisted' do
      event = UploadCertificateEvent.create(component: msa_component)
      expect(event).to_not be_valid
      expect(event.errors[:component]).to be_empty
    end

    it 'must reference an object' do
      event = UploadCertificateEvent.create
      expect(event.errors[:component]).to eql ['must exist', 'must exist']
    end
  end

  context '#trigger_publish_event' do
    it 'is triggered on creation' do
      event = UploadCertificateEvent.create!(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_value, component: msa_component)
      publish_event = PublishServicesMetadataEvent.last
      expect(event.id).to_not be_nil
      expect(event.id).to eql publish_event.event_id
    end
  end
end
