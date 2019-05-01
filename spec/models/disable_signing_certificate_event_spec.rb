require 'rails_helper'

RSpec.describe DisableSigningCertificateEvent, type: :model do
  include CertificateSupport
  root = PKI.new
  good_cert_value = root.generate_encoded_cert(expires_in: 2.months)
  expired_cert_value = root.generate_encoded_cert(expires_in: -2.months)
  component_params = { component_type: 'SP', name: 'Test Service Provider' }
  component = NewComponentEvent.create(component_params).component

  let(:signing_certificate) do
    UploadCertificateEvent.create(
        usage: 'signing', value: good_cert_value, component_id: component.id
    ).certificate
  end

  let(:expired_signing_certificate) do
    UploadCertificateEvent.create(
        usage: 'signing', value: expired_cert_value, component_id: component.id
    ).certificate
  end

  let(:encryption_certificate) do
    UploadCertificateEvent.create(
        usage: 'encryption', value: good_cert_value, component_id: component.id
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
    expect(cert.usage).to eq('encryption')
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
