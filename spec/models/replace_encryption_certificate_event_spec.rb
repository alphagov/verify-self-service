require 'rails_helper'
require 'auth_test_helper'

RSpec.describe ReplaceEncryptionCertificateEvent, type: :model do
  before(:each) do
    stub_auth
  end
  let(:component_name) { 'test component' }
  let(:component) do
    component_params = { component_type: 'MSA', name: component_name }
    NewComponentEvent.create(component_params).component
  end
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }
  let(:upload_encryption_cert) do
    UploadCertificateEvent.create(
      usage: CONSTANTS::ENCRYPTION, value: x509_cert, component_id: component.id
    ).certificate
  end

  def certificate_created_with(params = {})
    defaults = {
      usage: CONSTANTS::ENCRYPTION,
      value: x509_cert,
      component_id: component.id
    }
    Certificate.create(**defaults.merge(params))
  end
  
  it 'valid when encryption certificate is provided' do
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    )
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it 'valid with component encryption id set to encryption certificate id' do
    ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    )
    expect(component.encryption_certificate_id).to eq(upload_encryption_cert.id)
  end
  
  it 'invalid when encryption certificate is optional' do
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: nil
    )
    expect(event).not_to be_valid
    expect(event).not_to be_persisted
    expect(event.errors.messages[:certificate]).to eq(["can't be blank"])
  end
  
  it 'replace current encryption certificate with another' do
    new_encryption_certificate = UploadCertificateEvent.create(
      usage: CONSTANTS::ENCRYPTION, value: x509_cert, component_id: component.id
    ).certificate
    expect(component.encryption_certificate_id).not_to eq(new_encryption_certificate.id)

    ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    ).component
    expect(component.encryption_certificate_id).not_to eq(new_encryption_certificate.id)
    ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: new_encryption_certificate.id
    ).component

    expect(component.encryption_certificate_id).to eq(new_encryption_certificate.id)
  end

  it 'must error with invalid x509 certificate' do
    invalid = certificate_created_with(
      value: 'not valid'
    )
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: invalid.id
    )
    expect(event.errors[:certificate]).to eq ['is not a valid x509 certificate']
  end

  it 'must not be expired' do
    expired = certificate_created_with(
      value: root.generate_encoded_cert(expires_in: -1.months)
    )
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: expired.id
    )
    expect(event.errors[:certificate]).to eq ['has expired']
  end

  it 'must not expire within 1 month' do
    less_than_one_month = certificate_created_with(
      value: root.generate_encoded_cert(expires_in: 15.days)
    )
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: less_than_one_month.id
    )
    expect(event.errors[:certificate]).to eq ['expires too soon']
  end

  it 'must expire within 1 year' do
    more_than_one_year = certificate_created_with(
      value: root.generate_encoded_cert(expires_in: 2.years)
    )
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: more_than_one_year.id
    )
    expect(event.errors[:certificate]).to eq ['valid for too long']
  end
  
  context '#trigger_publish_event' do
    it 'when encryption certificate is replaced' do
      event = ReplaceEncryptionCertificateEvent.create(
        component: component, encryption_certificate_id: upload_encryption_cert.id
      )
      publish_event = PublishServicesMetadataEvent.last
      expect(event.id).to_not be_nil
      expect(event.id).to eq publish_event.event_id
    end
  end
end

