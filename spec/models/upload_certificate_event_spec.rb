require 'rails_helper'

include CertificateSupport

RSpec.describe UploadCertificateEvent, type: :model do

  root = PKI.new
  good_cert_value = root.generate_encoded_cert(expires_in: 2.months)
  component_params = { component_type: 'MSA', name:'fake_name' }
  component = NewComponentEvent.create(component_params).component
  include_examples 'has data attributes', UploadCertificateEvent, [:usage, :value, :component_id]
  include_examples 'is aggregated', UploadCertificateEvent, {usage: 'signing', value: good_cert_value, component_id: component.id }
  include_examples 'is a creation event', UploadCertificateEvent, {usage: 'signing', value: good_cert_value, component_id: component.id}

  context '#value' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['can\'t be blank']
    end
  end

  context '#certificate' do

    let(:root){ PKI.new }

    it 'must error with invalid x509 certificate' do
      event = UploadCertificateEvent.create(usage: 'signing', value: 'Not a valid certificate',component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['is not a valid x509 certificate']
    end

    it 'must allow base64 encoded DER format x509 certificate' do
      cert = root.generate_encoded_cert(expires_in: 2.months)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert, component_id: component.id)
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must allow PEM format x509 certificate' do
      cert = root.generate_signed_cert(expires_in: 2.months)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert.to_pem, component_id: component.id)
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must not be expired' do
      cert = root.generate_encoded_cert(expires_in: -1.months)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert, component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['has expired']
    end

    it 'must not expire within 1 month' do
      cert = root.generate_encoded_cert(expires_in: 15.days)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert, component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['expires too soon']
    end

    it 'must expire within 1 year' do
      cert = root.generate_encoded_cert(expires_in: 2.years)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert, component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['valid for too long']
    end

    it 'must be RSA' do
      cert = root.generate_signed_ec_cert(6.months)

      event = UploadCertificateEvent.create(usage: 'signing', value: cert.to_pem, component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['in not RSA']
    end

    it 'must be at least 2048 bits' do
      cert = root.generate_signed_rsa_cert_and_key(size: 1024)[0]

      event = UploadCertificateEvent.create(usage: 'signing', value: cert.to_pem, component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['key size is less than 2048']
    end

  end

  context '#usage' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'must be signing or encryption' do
      event = UploadCertificateEvent.create(usage: 'foobar', component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'happy when signing' do
      event = UploadCertificateEvent.create(usage: 'signing', component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end

    it 'happy when encryption' do
      event = UploadCertificateEvent.create(usage: 'encryption', component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end
  end

  context "#component" do
    it 'reads from component_id' do
      event = UploadCertificateEvent.new(component_id: component.id)
      expect(event.component).to eql component
    end

    it 'refreshes when component_id changes' do
      event = UploadCertificateEvent.new(component_id: component.id)
      expect(event.component).to eql component
      second_component = NewComponentEvent.create(component_params).component

      event.component_id = second_component.id
      expect(event.component).to_not eql component
      expect(event.component).to eql second_component
    end


  end

  context '#component=' do
    it 'will set component_id when called during ::create' do
      event = UploadCertificateEvent.create(usage: 'signing', component_id: component.id)
      expect(event.component).to eql component
    end

    it 'will set component_id when called directly' do
      event = UploadCertificateEvent.new
      event.component = component
      expect(event.component).to eql component
      expect(event.component_id).to eql component.id
    end

    it 'must be persisted' do
      event = UploadCertificateEvent.create(component: Component.new)
      expect(event).to_not be_valid
      expect(event.errors[:component]).to eql ['must exist']
    end

    it 'must be persisted' do
      event = UploadCertificateEvent.create(component_id: component.id)
      expect(event).to_not be_valid
      expect(event.errors[:component]).to be_empty
    end

    it 'must reference an object' do
      event = UploadCertificateEvent.create
      expect(event.errors[:component]).to eql ['must exist']
    end
  end

  context '#trigger_publish_event' do
      it 'is triggered on creation' do
        event = UploadCertificateEvent.create!(usage: 'signing', value: good_cert_value, component_id: component.id)
        publish_event = PublishServicesMetadataEvent.last
        expect(event.id).to_not be_nil
        expect(event.id).to eql publish_event.event_id
      end
  end
end
