require 'rails_helper'

RSpec.describe CertificateInUseEvent, type: :model do
  it 'is valid and persisted with hub_use_confirmation_at not nil' do
    certificate = create(:sp_signing_certificate)
    expect(certificate.in_use_at).to be_nil
    certificate_in_use_event = create(:certificate_in_use_event, certificate: certificate)
    expect(certificate_in_use_event).to be_valid
    expect(certificate_in_use_event).to be_persisted
    expect(certificate.in_use_at).not_to be_nil
  end
end
