require 'rails_helper'
require_relative '../support/certificate_support'
require_relative '../support/pki'

include CertificateSupport

RSpec.describe Certificate, type: :model do

  root = PKI.new
  good_cert = root.sign(generate_cert_with_expiry(Time.now + 2.months))
  good_cert_value = PKI.inline_pem(good_cert)

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
