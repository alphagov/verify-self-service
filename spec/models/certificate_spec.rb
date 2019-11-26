require 'rails_helper'

RSpec.describe Certificate, type: :model do

  it 'is valid with valid attributes' do
    expect(build(:msa_signing_certificate)).to be_valid
    expect(build(:msa_encryption_certificate)).to be_valid
  end

  it 'is not valid with non-valid attributes' do
    expect(build(:msa_signing_certificate, usage: 'blah')).to_not be_valid
  end

  it 'is not valid without a usage and/or value' do
    expect(build(:msa_signing_certificate, usage: nil)).to_not be_valid
    expect(build(:msa_signing_certificate, value: nil)).to_not be_valid
    expect(build(:msa_signing_certificate, usage: nil, value: nil)).to_not be_valid
  end

  it 'has events' do
    event = create(:upload_certificate_event)
    expect(event.certificate.events.last).to eql(event)
  end

  it 'holds valid metadata' do
    certificate = build(:msa_signing_certificate)

    subject = certificate.x509.subject.to_s
    expect(certificate).not_to be_nil
    expect(certificate.to_metadata).to include(name: subject, value: certificate.value)
  end
end
