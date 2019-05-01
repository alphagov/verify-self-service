require 'rails_helper'

RSpec.describe EnableSigningCertificateEvent, type: :model do
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

  def enable_signing_certificate_event
    EnableSigningCertificateEvent.create(certificate: signing_certificate)
  end

  def disable_signing_certificate_event
    DisableSigningCertificateEvent.create(certificate: signing_certificate)
  end

  it 'must be persisted' do
    event = enable_signing_certificate_event
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it 'signing certificate is enabled by default' do
    cert = enable_signing_certificate_event.certificate
    expect(cert.enabled).to eq(true)
  end

  it 'can enable a disabled certificate' do
    disabled_cert = disable_signing_certificate_event.certificate
    expect(disabled_cert.enabled).to eq(false)
    enabled_cert = enable_signing_certificate_event.certificate
    expect(enabled_cert.enabled).to eq(true)
    expect(enabled_cert.enabled).to eq(disabled_cert.enabled)
  end

  it 'cannot be created with expired certificate' do
    event = EnableSigningCertificateEvent.create(
      certificate: expired_signing_certificate
    )
    expect(event.certificate).not_to be_valid
    expect(event).not_to be_persisted
  end

  it 'must be signing' do
    event = EnableSigningCertificateEvent.create(
      certificate: encryption_certificate
    )
    cert = event.certificate
    expect(cert.usage).to eq('encryption')
    expect(event).not_to be_persisted
  end
end
