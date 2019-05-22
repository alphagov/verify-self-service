require 'rails_helper'
include CertificateSupport

RSpec.describe Certificate, type: :model do
  let(:pki) { PKI.new }
  let(:good_cert_value) do
    pki.generate_signed_cert(expires_in: 2.months).to_pem
  end
  
  entity_id = 'http://test-entity-id'
  component_params = { component_type: 'MSA', name: 'fake_name', entity_id: entity_id }
  let(:component) { NewComponentEvent.create(component_params).component }
  
  it 'is valid with valid attributes' do
    expect(Certificate.new(usage: CONSTANTS::SIGNING, value: good_cert_value, component_id: component.id)).to be_valid
    expect(Certificate.new(usage: CONSTANTS::ENCRYPTION, value: good_cert_value, component_id:component.id)).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(Certificate.new(usage: 'blah', value: good_cert_value, component_id:component.id)).to_not be_valid
  end

  it 'is not valid without a usage and/or value' do
    expect(Certificate.new(usage: nil, value: good_cert_value, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: CONSTANTS::SIGNING, value: nil, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil, component_id: component.id)).to_not be_valid
  end

  it 'has events' do
    event = UploadCertificateEvent.create!(usage: CONSTANTS::SIGNING, value: good_cert_value, component_id: component.id)
    certificate = event.certificate
    expect([certificate.events.last]).to eql [event]
  end

  it 'holds valid metadata' do
    cert = Base64.encode64(good_cert_value)
    certificate = Certificate.new(usage: CONSTANTS::SIGNING, value: cert, component_id: component.id)
    subject = certificate.x509.subject.to_s
    expect(certificate).not_to be_nil
    expect(certificate.to_metadata).to include(name: subject, value: cert)
  end
end
