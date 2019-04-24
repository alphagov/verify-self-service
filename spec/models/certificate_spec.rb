require 'rails_helper'

include CertificateSupport

RSpec.describe Certificate, type: :model do
  let(:pki) { PKI.new }
  let(:good_cert_value) do
    pki.generate_signed_cert(expires_in: 2.months).to_pem
  end

  component_params = { component_type: 'MSA', name: 'fake_name' }
  let(:component) { NewComponentEvent.create(component_params).component }
  
  it 'is valid with valid attributes' do
    expect(Certificate.new(usage: 'signing', value: good_cert_value, component_id: component.id)).to be_valid
    expect(Certificate.new(usage: 'encryption', value: good_cert_value, component_id:component.id)).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(Certificate.new(usage: 'blah', value: good_cert_value, component_id:component.id)).to_not be_valid
  end

  it 'is not valid without a usage and/or value' do
    expect(Certificate.new(usage: nil, value: good_cert_value, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: 'signing', value: nil, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil, component_id: component.id)).to_not be_valid
  end

  it 'has events' do
    event = UploadCertificateEvent.create!(usage: 'signing', value: good_cert_value, component_id: component.id)
    certificate = event.certificate
    expect([certificate.events.last]).to eql [event]
  end

  it 'holds valid metadata' do
    cert = Base64.encode64(good_cert_value)
    certificate = Certificate.new(usage: 'signing', value: cert, component_id: component.id)
    subject = certificate_subject(cert)
    expect(certificate).not_to be_nil
    expect(certificate.to_metadata).to include(name: subject, value: cert)
  end
end
