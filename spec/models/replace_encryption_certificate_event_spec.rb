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
  let(:upload_encryption_cert) do
    x509_cert = root.generate_encoded_cert(expires_in: 9.months)
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

  it 'creates with component encryption id set to encryption certificate id' do
    this_component = ReplaceEncryptionCertificateEvent.create(
      component: component, encryption_certificate_id: upload_encryption_cert.id
    ).component
    expect(this_component.encryption_certificate_id).to eq(upload_encryption_cert.id)
  end
end
