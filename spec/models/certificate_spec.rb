require 'rails_helper'

RSpec.describe Certificate, type: :model do
  include CertificateSupport

  let(:pki) { PKI.new }
  let(:good_cert_value) do
    pki.generate_signed_cert(expires_in: 2.months).to_pem
  end

  let(:component) { create(:msa_component) }

  it 'is valid with valid attributes' do
    expect(Certificate.new(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_value, component: component)).to be_valid
    expect(Certificate.new(usage: CERTIFICATE_USAGE::ENCRYPTION, value: good_cert_value, component: component)).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(Certificate.new(usage: 'blah', value: good_cert_value, component: component)).to_not be_valid
  end

  it 'is not valid without a usage and/or value' do
    expect(Certificate.new(usage: nil, value: good_cert_value, component: component)).to_not be_valid
    expect(Certificate.new(usage: CERTIFICATE_USAGE::SIGNING, value: nil, component: component)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil, component: component)).to_not be_valid
  end

  it 'has events' do
    event = UploadCertificateEvent.create!(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_value, component: component)
    certificate = event.certificate
    expect([certificate.events.last]).to eql [event]
  end

  it 'holds valid metadata' do
    cert = Base64.encode64(good_cert_value)
    certificate = Certificate.new(usage: CERTIFICATE_USAGE::SIGNING, value: cert, component: component)
    subject = certificate.x509.subject.to_s
    expect(certificate).not_to be_nil
    expect(certificate.to_metadata).to include(name: subject, value: cert)
  end
end
