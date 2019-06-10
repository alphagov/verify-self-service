require 'rails_helper'

RSpec.describe DisableSigningCertificateEvent, type: :model do
  include CertificateSupport
  root = PKI.new
  good_cert_value = root.generate_encoded_cert(expires_in: 2.months)
  expired_cert_value = root.generate_encoded_cert(expires_in: -2.months)
  component_params = { component_type: CONSTANTS::SP, name: 'Test Service Provider' }
  component = NewSpComponentEvent.create(component_params).sp_component

  let(:signing_certificate) do
    UploadCertificateEvent.create(
      usage: CONSTANTS::SIGNING, value: good_cert_value, component: component
    ).certificate
  end

  let(:expired_signing_certificate) do
    UploadCertificateEvent.create(
      usage: CONSTANTS::SIGNING, value: expired_cert_value, component: component
    ).certificate
  end

  let(:encryption_certificate) do
    UploadCertificateEvent.create(
      usage: CONSTANTS::ENCRYPTION, value: good_cert_value, component: component
    ).certificate
  end

  def disable_signing_certificate_event
    DisableSigningCertificateEvent.create(certificate: signing_certificate)
  end


  it 'disables a signing certificate' do
    cert = disable_signing_certificate_event.certificate
    expect(cert.enabled).to eq(false)
  end

  it 'must be persisted' do
    event = disable_signing_certificate_event
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it 'cannot be created with expired certificate' do
    event = DisableSigningCertificateEvent.create(
      certificate: expired_signing_certificate
    )
    expect(event.certificate).not_to be_valid
    expect(event).not_to be_persisted
  end

  it 'must be signing' do
    event = DisableSigningCertificateEvent.create(
      certificate: encryption_certificate
    )
    cert = event.certificate
    expect(cert.usage).to eq(CONSTANTS::ENCRYPTION)
    expect(event).not_to be_persisted
  end

  context '#trigger_publish_event' do
    it 'when signing certificate is disabled' do
      event = disable_signing_certificate_event
      publish_event = PublishServicesMetadataEvent.last
      expect(event.id).to_not be_nil
      expect(event.id).to eql publish_event.event_id
    end
  end
end
