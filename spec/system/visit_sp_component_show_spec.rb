require 'rails_helper'
require 'auth_test_helper'

RSpec.describe 'Components Page', type: :system do
  before(:each) do
    stub_auth
  end

  entity_id = 'http://test-entity-id'
  component_name = 'test component'
  component_params = { name: component_name, component_type: CONSTANTS::SP }

  let(:component) { NewSpComponentEvent.create(component_params).sp_component }
  let(:root) { PKI.new }
  let(:upload_certs) do
    x509_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
    x509_cert_2 = root.generate_encoded_cert(expires_in: 9.months)
    UploadCertificateEvent.create(
      usage: CONSTANTS::SIGNING, value: x509_cert_1, component: component
    ).certificate
    UploadCertificateEvent.create(
      usage: CONSTANTS::SIGNING, value: x509_cert_2, component: component
    ).certificate
  end
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 2.months) }
  let(:upload_encryption_cert) do
    encryption_cert = UploadCertificateEvent.create(
      usage: CONSTANTS::ENCRYPTION, value: x509_cert, component: component
    ).certificate
    ReplaceEncryptionCertificateEvent.create(
      component: component,
      encryption_certificate_id: encryption_cert.id
    ).component.encryption_certificate
  end

  let(:show_page) { ShowComponentCertificatesForm.new }

  it 'successfully displays an existing component' do
    visit sp_component_path(component.id)

    expect(page).to have_selector('h1', text: component_name)
    expect(page).to have_link 'Upload'
  end

  it 'shows list of enabled signing certificates' do
    upload_certs
    certs = component.certificates
    visit sp_component_path(component.id)
    expect(show_page).to have_enabled_signing_certificate(certs[0])
    expect(show_page).to have_enabled_signing_certificate(certs[1])
  end

  it 'successfully disables a certificate' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit sp_component_path(component.id)

    expect(show_page).to have_enabled_signing_certificate(certs[0])
    show_page.disable_signing_certificate(certs[0])

    expect(show_page).to have_selector('h1', text: component_name)
    expect(show_page).to have_disabled_signing_certificate(certs[0])
    expect(show_page).to have_enabled_signing_certificate(certs[1])
  end

  it 'shows list of disabled certificates' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit sp_component_path(component.id)

    certs.each do |certificate|
      show_page.disable_signing_certificate(certificate)
    end

    disabled_certs = component.disabled_signing_certificates

    expect(show_page).to have_selector('h1', text: component_name)
    expect(show_page).to have_disabled_signing_certificate(disabled_certs[0])
    expect(show_page).to have_disabled_signing_certificate(disabled_certs[1])
  end

  it 'displays encryption certificate for component' do
    upload_encryption_cert
    visit sp_component_path(component.id)
    certificate = component.encryption_certificate
    expect(show_page).to have_encryption_certificate(certificate)
  end

  it 'does not display encryption certificate section when optional' do
    ReplaceEncryptionCertificateEvent.create(
      component: component,
      encryption_certificate_id: nil
    )
    visit sp_component_path(component.id)
    certificate = component.encryption_certificate
    expect(certificate).to be_nil
    expect(show_page).not_to have_encryption_certificate(certificate)
  end

  it 'can replace encryption certificate with a different one' do
    upload_encryption_cert
    new_cert = UploadCertificateEvent.create(
      usage: CONSTANTS::ENCRYPTION, value: x509_cert, component: component
    ).certificate
    visit sp_component_path(component.id)
    current_cert = component.encryption_certificate
    expect(show_page).to have_encryption_certificate(current_cert)

    show_page.replace_encryption_certificate(new_cert)
    expect(show_page).to have_encryption_certificate(new_cert)
  end

  it 'will not replace encryption certificate with an invalid certificate' do
    upload_encryption_cert
    invalid_cert = Certificate.create(
      usage: CONSTANTS::ENCRYPTION, value: "invalid", component: component
    )
    visit sp_component_path(component.id)

    expect(show_page).to have_previous_encryption_certificate(invalid_cert)

    show_page.replace_encryption_certificate(invalid_cert)
    expect(show_page).not_to have_encryption_certificate(invalid_cert)
    expect(show_page).to have_content 'Certificate is not a valid x509 certificate'
  end

  it 'successfully enables a certificate' do
    upload_certs
    certs = component.enabled_signing_certificates
    visit sp_component_path(component.id)

    certs.each do |certificate|
      show_page.disable_signing_certificate(certificate)
    end

    disabled_certs = component.disabled_signing_certificates
    expect(show_page).to have_disabled_signing_certificate(disabled_certs[0])
    show_page.enable_signing_certificate(disabled_certs[0])

    expect(show_page).to have_selector('h1', text: component_name)
    expect(show_page).to have_enabled_signing_certificate(disabled_certs[0])
  end
end
