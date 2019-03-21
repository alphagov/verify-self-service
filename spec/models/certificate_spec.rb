require 'rails_helper'

include CertificateSupport

RSpec.describe Certificate, type: :model do

  let(:good_cert_value) {
    root = PKI.new
    root.generate_signed_cert(expires_in: 2.months).to_pem
  }

  it "is valid with valid attributes" do
    expect(Certificate.new(usage: 'signing', value: good_cert_value)).to be_valid
    expect(Certificate.new(usage: 'encryption', value: good_cert_value)).to be_valid
  end

  it "is not valid with non-valid attributes" do
    expect(Certificate.new(usage: 'blah', value: good_cert_value)).to_not be_valid
  end

  it "is not valid without a usage and/or value" do
    expect(Certificate.new(usage: nil, value: good_cert_value)).to_not be_valid
    expect(Certificate.new(usage: 'signing', value: nil)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil)).to_not be_valid
  end

  it 'has events' do
    event = UploadCertificateEvent.create!(usage: 'signing', value: good_cert_value)
    certificate = event.certificate
    expect(certificate.events.to_a).to eql [event]
  end
end
