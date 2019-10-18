require 'rails_helper'

RSpec.describe DisableSigningCertificateEvent, type: :model do
  include CertificateSupport
  root = PKI.new
  good_cert_value = root.generate_encoded_cert(expires_in: 2.months)
  let(:component) { create(:sp_component) }

  let(:upload_signing_certificate_primary) {
    create(:upload_certificate_event, component: component)
  }

  let(:upload_signing_certificate_secondary) do
    create(:upload_certificate_event, component: component)
  end


  it 'disables a secondary signing certificate and persists' do
    upload_signing_certificate_primary
    upload_signing_certificate_secondary

    event = DisableSigningCertificateEvent.create(
      certificate: upload_signing_certificate_secondary.certificate
    )
    cert = upload_signing_certificate_secondary.certificate
    expect(cert.enabled).to eq(false)
    expect(event.errors).to be_empty
    expect(event).to be_persisted
  end

  it 'does not allow disabling a cert if it is the only one' do
    upload_signing_certificate_primary
    upload_signing_certificate_secondary

    expect(component.enabled_signing_certificates.length).to eq 2

    disable_secondary_event = DisableSigningCertificateEvent.create(
      certificate: upload_signing_certificate_secondary.certificate
    )
    secondary_cert = upload_signing_certificate_secondary.certificate
    expect(secondary_cert.enabled).to eq(false)
    expect(disable_secondary_event.errors).to be_empty
    expect(disable_secondary_event).to be_persisted
    expect(secondary_cert.component.enabled_signing_certificates.length).to eq 1

    disable_primary_event = DisableSigningCertificateEvent.create(
      certificate: upload_signing_certificate_primary.certificate
    )
    primary_cert = upload_signing_certificate_primary.certificate
    expect(primary_cert.enabled).to eq(true)
    expect(disable_primary_event.errors[:certificate]).to eq([t('certificates.errors.cannot_disable')])
    expect(disable_primary_event).not_to be_persisted
    expect(primary_cert.component.enabled_signing_certificates.length).to eq 1
  end

  it 'must be signing' do
    event = DisableSigningCertificateEvent.create(
      certificate: create(:sp_encryption_certificate, component: component)
    )
    cert = event.certificate
    expect(cert.usage).to eq(CERTIFICATE_USAGE::ENCRYPTION)
    expect(event).not_to be_persisted
  end

  context '#trigger_publish_event' do
    it 'when signing certificate is disabled' do
      upload_signing_certificate_primary
      upload_signing_certificate_secondary
      event = DisableSigningCertificateEvent.create(
        certificate: upload_signing_certificate_secondary.certificate
      )

      resulting_event = PublishServicesMetadataEvent.all.select do |evt|
        evt.event_id == event.id
      end.first

      expect(resulting_event).to be_present
    end
  end
end
