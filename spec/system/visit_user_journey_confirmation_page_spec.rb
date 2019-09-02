require 'rails_helper'

RSpec.describe 'Confirmation page', type: :system do
  include CertificateSupport

  let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate) }

  before(:each) do
    login_certificate_manager_user
    ReplaceEncryptionCertificateEvent.create(
      component: sp_encryption_certificate.component,
      encryption_certificate_id: sp_encryption_certificate.id
    )
    ReplaceEncryptionCertificateEvent.create(
      component: msa_encryption_certificate.component,
      encryption_certificate_id: msa_encryption_certificate.id
    )
  end

  context 'shows confirmation page for msa' do
    it 'encryption and successfully goes to next page' do
      msa_component = msa_encryption_certificate.component
      visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content 'MSA'
      expect(page).to have_content 'delete the old encryption key and certificate from your MSA configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:msa_signing_certificate)
      msa_component = certificate.component
      visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
      expect(page).to have_content 'MSA'
      expect(page).to have_content 'delete the old signing key and certificate from your MSA configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end

  context 'shows confirmation page for sp' do
    it 'encryption and successfully goes to next page' do
      sp_component = sp_encryption_certificate.component
      visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'VSP'
      expect(page).to have_content 'delete the old encryption key and certificate from your VSP configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:sp_signing_certificate)
      sp_component = certificate.component
      visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
      expect(page).to have_content 'VSP'
      expect(page).to have_content 'delete the old signing key and certificate from your VSP configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end
end
