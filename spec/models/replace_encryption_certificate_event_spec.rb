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

  it 'creates valid and persisted replace encryption certificate event' do
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    )
    expect(event).to be_valid
    expect(event).to be_persisted
  end
  
  it 'creates valid event when encryption certificate is optional' do
    event = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: nil
    )
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it 'creates with component encryption id set to encryption certificate id' do
    ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    )
    expect(component.encryption_certificate_id).to eq(upload_encryption_cert.id)
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
end
