require 'rails_helper'

RSpec.shared_examples "show component page" do |component_type|
  include ComponentSupport
  before(:each) do
    login_component_manager_user
  end
  let(:component) { component_by_type(component_type) }
  let(:root) { PKI.new }
  let(:upload_certs) do
    UploadCertificateEvent.create(
      usage: CERTIFICATE_USAGE::SIGNING,
      value: root.generate_encoded_cert(expires_in: 2.months),
      component: component
    ).certificate
    UploadCertificateEvent.create(
      usage: CERTIFICATE_USAGE::SIGNING,
      value: root.generate_encoded_cert(expires_in: 2.months),
      component: component
    ).certificate
  end
  let(:upload_encryption_cert) do
    encryption_cert = UploadCertificateEvent.create(
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: root.generate_encoded_cert(expires_in: 2.months),
      component: component
    ).certificate
    ReplaceEncryptionCertificateEvent.create(
      component: component,
      encryption_certificate_id: encryption_cert.id
    ).component.encryption_certificate
  end

  let(:show_page) { ShowComponentCertificatesForm.new }

  context "when visiting #{component_type} show page" do
    it 'successfully displays an existing component' do
      visit polymorphic_url(component)

      expect(page).to have_selector('h1', text: component.name)
      expect(page).to have_link 'Upload'
    end

    it 'shows list of enabled signing certificates' do
      upload_certs
      certs = component.certificates
      visit polymorphic_url(component)

      expect(show_page).to have_enabled_signing_certificate(certs[0])
      expect(show_page).to have_enabled_signing_certificate(certs[1])
    end

    it 'successfully disables a certificate' do
      upload_certs
      certs = component.enabled_signing_certificates
      visit polymorphic_url(component)

      expect(show_page).to have_enabled_signing_certificate(certs[0])
      show_page.disable_signing_certificate(certs[0])

      expect(show_page).to have_selector('h1', text: component.name)
      expect(show_page).to have_disabled_signing_certificate(certs[0])
      expect(show_page).to have_enabled_signing_certificate(certs[1])
    end

    it 'shows list of disabled certificates' do
      upload_certs
      certs = component.enabled_signing_certificates
      visit polymorphic_url(component)

      certs.each do |certificate|
        show_page.disable_signing_certificate(certificate)
      end

      disabled_certs = component.disabled_signing_certificates

      expect(show_page).to have_selector('h1', text: component.name)
      expect(show_page).to have_disabled_signing_certificate(disabled_certs[0])
      expect(show_page).to have_disabled_signing_certificate(disabled_certs[1])
    end

    it 'displays encryption certificate for component' do
      upload_encryption_cert
      visit polymorphic_url(component)
      certificate = component.encryption_certificate
      expect(show_page).to have_encryption_certificate(certificate)
    end

    it 'does not display encryption certificate section when optional' do
      ReplaceEncryptionCertificateEvent.create(
        component: component,
        encryption_certificate_id: nil
      )
      visit polymorphic_url(component)
      certificate = component.encryption_certificate
      expect(certificate).to be_nil
      expect(show_page).not_to have_encryption_certificate(certificate)
    end

    it 'can replace encryption certificate with a different one' do
      upload_encryption_cert
      new_cert = UploadCertificateEvent.create(
        usage: CERTIFICATE_USAGE::ENCRYPTION,
        value: root.generate_encoded_cert(expires_in: 2.months),
        component: component
      ).certificate
      visit polymorphic_url(component)
      current_cert = component.encryption_certificate
      expect(show_page).to have_encryption_certificate(current_cert)

      show_page.replace_encryption_certificate(new_cert)
      expect(show_page).to have_encryption_certificate(new_cert)
    end

    it 'will not replace encryption certificate with an invalid certificate' do
      upload_encryption_cert
      invalid_cert = Certificate.create(
        usage: CERTIFICATE_USAGE::ENCRYPTION, value: "invalid", component: component
      )
      visit polymorphic_url(component)

      expect(show_page).to have_previous_encryption_certificate(invalid_cert)

      show_page.replace_encryption_certificate(invalid_cert)
      expect(show_page).not_to have_encryption_certificate(invalid_cert)
      expect(show_page).to have_content 'Certificate is not a valid x509 certificate'
    end

    it 'successfully enables a certificate' do
      upload_certs
      certs = component.enabled_signing_certificates
      visit polymorphic_url(component)

      certs.each do |certificate|
        show_page.disable_signing_certificate(certificate)
      end

      disabled_certs = component.disabled_signing_certificates
      expect(show_page).to have_disabled_signing_certificate(disabled_certs[0])
      show_page.enable_signing_certificate(disabled_certs[0])

      expect(show_page).to have_selector('h1', text: component.name)
      expect(show_page).to have_enabled_signing_certificate(disabled_certs[0])
    end
  end

  context 'when visiting a component with a different type' do
    it 'does not show certificates for another component with the same id' do
      MsaComponent.destroy_all
      SpComponent.destroy_all
      upload_certs
      certs = component.certificates
      other_component = alternative_component(component.component_type)
      other_component.id = component.id
      other_component.save!

      visit polymorphic_url(other_component)
      show_page = ShowComponentCertificatesForm.new

      certs.each do |cert|
        expect(show_page).to_not have_enabled_signing_certificate(cert)
      end
    end
  end
end
